import Foundation
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class AppViewModel: ObservableObject {
    @Published var accountUsages: [AccountUsage] = []
    @Published var isLoading = false
    @Published var lastRefreshTime: Date?
    @Published var remoteGroups: [GroupSummary]?

    @AppStorage("accountsDirectory") var accountsDirectory = "~/.cliproxyapi-stats/accounts"
    @AppStorage("refreshInterval") var refreshInterval = 300 {
        didSet { restartTimer() }
    }
    @AppStorage("maxConcurrentRequests") var maxConcurrentRequests = 8
    @AppStorage("launchAtLogin") var launchAtLogin = true {
        didSet { updateLaunchAtLogin() }
    }
    @AppStorage("weeklyExhaustedZeroes5H") var weeklyExhaustedZeroes5H = true
    @AppStorage("priorityType") var priorityType = ""
    @AppStorage("mixTypes") var mixTypes = true
    @AppStorage("proxyEnabled") var proxyEnabled = false {
        didSet { applyProxy() }
    }
    @AppStorage("proxyHost") var proxyHost = "127.0.0.1" {
        didSet { applyProxy() }
    }
    @AppStorage("proxyPort") var proxyPort = 1080 {
        didSet { applyProxy() }
    }
    @AppStorage("dataSourceMode") var dataSourceMode = "local"
    @AppStorage("remoteServiceURL") var remoteServiceURL = ""

    private let accountLoader = AccountLoader()
    private let usageService = UsageService()
    private let remoteService = RemoteService()
    private var fileWatcher: FileWatcher?
    private var timerCancellable: AnyCancellable?
    private var fileWatcherDebounceTask: Task<Void, Never>?
    private var hasStarted = false
    private var refreshGeneration = 0

    // MARK: - Computed Properties

    var isRemoteMode: Bool { dataSourceMode == "remote" }

    var groupSummaries: [GroupSummary] {
        if isRemoteMode, let remoteGroups { return remoteGroups }
        let grouped = Dictionary(grouping: accountUsages, by: \.type)
        return grouped.map { GroupSummary(type: $0.key, usages: $0.value, weeklyExhaustedZeroes5H: weeklyExhaustedZeroes5H) }
            .sorted { $0.type < $1.type }
    }

    var averageRemainingPercent: Int {
        let valid = accountUsages.filter { $0.error == nil && !$0.isLoading }
        guard !valid.isEmpty else { return 0 }
        return valid.map { effectivePrimaryRemaining($0) }.reduce(0, +) / valid.count
    }

    var menuBarRemainingPercent: Int {
        guard !mixTypes, !priorityType.isEmpty else {
            return averageRemainingPercent
        }
        let filtered = accountUsages.filter { $0.type == priorityType && $0.error == nil && !$0.isLoading }
        guard !filtered.isEmpty else { return 0 }
        return filtered.map { effectivePrimaryRemaining($0) }.reduce(0, +) / filtered.count
    }

    func effectivePrimaryRemaining(_ usage: AccountUsage) -> Int {
        if weeklyExhaustedZeroes5H, (usage.secondaryRemainingPercent ?? 100) <= 0 {
            return 0
        }
        return usage.primaryRemainingPercent
    }

    var menuBarColor: Color {
        let pct = averageRemainingPercent
        if pct >= 50 { return .green }
        if pct >= 20 { return .yellow }
        return .red
    }

    // MARK: - Lifecycle

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        applyProxy()
        if !isRemoteMode { setupFileWatcher() }
        startTimer()
        Task { await refresh() }
    }

    private func applyProxy() {
        Task {
            if proxyEnabled {
                await usageService.updateProxy(host: proxyHost, port: proxyPort)
            } else {
                await usageService.updateProxy(host: nil, port: nil)
            }
        }
    }

    // MARK: - Refresh

    var hasFailedAccounts: Bool {
        !isRemoteMode && accountUsages.contains { $0.error != nil }
    }

    func refreshFailed() async {
        guard !isRemoteMode else { return }
        let failedIds = accountUsages.compactMap { $0.error != nil ? $0.id : nil }
        guard !failedIds.isEmpty else { return }

        isLoading = true
        let accounts = accountLoader.loadAccounts(from: accountsDirectory)

        for usageId in failedIds {
            guard let account = accounts.first(where: { "\($0.email)|\($0.type)" == usageId }) else { continue }
            if let idx = accountUsages.firstIndex(where: { $0.id == usageId }) {
                accountUsages[idx] = AccountUsage(loadingFrom: account)
            }
        }

        await withTaskGroup(of: Void.self) { group in
            for usageId in failedIds {
                guard let account = accounts.first(where: { "\($0.email)|\($0.type)" == usageId }) else { continue }
                group.addTask {
                    let newUsage = await self.usageService.fetchUsage(for: account)
                    await MainActor.run {
                        if let idx = self.accountUsages.firstIndex(where: { $0.id == usageId }) {
                            self.accountUsages[idx] = newUsage
                        }
                    }
                }
            }
        }

        lastRefreshTime = Date()
        isLoading = false
    }

    func refresh() async {
        isLoading = true
        if isRemoteMode {
            await refreshRemote()
        } else {
            await refreshLocal()
        }
    }

    private func refreshRemote() async {
        let url = remoteServiceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else {
            accountUsages = []
            remoteGroups = nil
            isLoading = false
            return
        }

        do {
            let response = try await remoteService.fetch(url: url)
            accountUsages = response.accounts.map { AccountUsage(remote: $0) }
                .sorted { $0.email < $1.email }
            remoteGroups = response.groups.map { GroupSummary(remoteGroup: $0) }
                .sorted { $0.type < $1.type }
            lastRefreshTime = Date()
        } catch {
            remoteGroups = nil
            accountUsages = []
        }
        isLoading = false
    }

    private func refreshLocal() async {
        let accounts = accountLoader.loadAccounts(from: accountsDirectory)
        let sortedAccounts = accounts.sorted { $0.email < $1.email }

        refreshGeneration += 1
        let currentGeneration = refreshGeneration

        accountUsages = sortedAccounts.map { AccountUsage(loadingFrom: $0) }
        await fetchUsagesIncrementally(sortedAccounts, generation: currentGeneration)

        if currentGeneration == refreshGeneration {
            lastRefreshTime = Date()
            isLoading = false
        }
    }

    func refreshSingleAccount(_ usageId: String) async {
        guard !isRemoteMode else { return }
        let accounts = accountLoader.loadAccounts(from: accountsDirectory)
        guard let account = accounts.first(where: { "\($0.email)|\($0.type)" == usageId }) else {
            if let idx = accountUsages.firstIndex(where: { $0.id == usageId }) {
                let current = accountUsages[idx]
                accountUsages[idx] = AccountUsage(account: Account(
                    accessToken: "", accountId: nil, disabled: false,
                    email: current.email, expired: nil, idToken: "",
                    lastRefresh: "", refreshToken: "", type: current.type
                ), error: "账号文件不存在")
            }
            return
        }

        if let idx = accountUsages.firstIndex(where: { $0.id == usageId }) {
            accountUsages[idx] = AccountUsage(loadingFrom: account)
        }

        let newUsage = await usageService.fetchUsage(for: account)

        if let newIdx = accountUsages.firstIndex(where: { $0.id == usageId }) {
            accountUsages[newIdx] = newUsage
        }
    }

    private func fetchUsagesIncrementally(_ accounts: [Account], generation: Int) async {
        let maxConcurrent = max(1, maxConcurrentRequests)

        await withTaskGroup(of: (Int, AccountUsage).self) { group in
            var nextIndex = 0
            let initialCount = min(maxConcurrent, accounts.count)

            for _ in 0..<initialCount {
                let idx = nextIndex
                let account = accounts[idx]
                nextIndex += 1
                group.addTask {
                    (idx, await self.usageService.fetchUsage(for: account))
                }
            }

            while let (index, usage) = await group.next() {
                guard generation == self.refreshGeneration else { return }
                if index < self.accountUsages.count, self.accountUsages[index].id == usage.id {
                    self.accountUsages[index] = usage
                }

                guard nextIndex < accounts.count else { continue }
                let nextIdx = nextIndex
                let account = accounts[nextIdx]
                nextIndex += 1
                group.addTask {
                    (nextIdx, await self.usageService.fetchUsage(for: account))
                }
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timerCancellable = Timer.publish(every: TimeInterval(refreshInterval), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.refresh() }
            }
    }

    private func restartTimer() {
        timerCancellable?.cancel()
        startTimer()
    }

    // MARK: - File Watcher

    private func setupFileWatcher() {
        fileWatcher?.stop()
        fileWatcher = FileWatcher(path: accountsDirectory) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.fileWatcherDebounceTask?.cancel()
                self.fileWatcherDebounceTask = Task {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    await self.refresh()
                }
            }
        }
        fileWatcher?.start()
    }

    // MARK: - Launch at Login

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently handle - user can toggle again
        }
    }
}
