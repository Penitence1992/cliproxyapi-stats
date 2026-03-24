import Foundation
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class AppViewModel: ObservableObject {
    @Published var accountUsages: [AccountUsage] = []
    @Published var isLoading = false
    @Published var lastRefreshTime: Date?

    @AppStorage("accountsDirectory") var accountsDirectory = "~/.cliproxyapi-stats/accounts"
    @AppStorage("refreshInterval") var refreshInterval = 300 {
        didSet { restartTimer() }
    }
    @AppStorage("launchAtLogin") var launchAtLogin = true {
        didSet { updateLaunchAtLogin() }
    }
    @AppStorage("weeklyExhaustedZeroes5H") var weeklyExhaustedZeroes5H = true
    @AppStorage("priorityType") var priorityType = ""
    @AppStorage("mixTypes") var mixTypes = true

    private let accountLoader = AccountLoader()
    private let usageService = UsageService()
    private var fileWatcher: FileWatcher?
    private var timerCancellable: AnyCancellable?
    private var fileWatcherDebounceTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var groupSummaries: [GroupSummary] {
        let grouped = Dictionary(grouping: accountUsages, by: \.type)
        return grouped.map { GroupSummary(type: $0.key, usages: $0.value, weeklyExhaustedZeroes5H: weeklyExhaustedZeroes5H) }
            .sorted { $0.type < $1.type }
    }

    var averageRemainingPercent: Int {
        let valid = accountUsages.filter { $0.error == nil }
        guard !valid.isEmpty else { return 0 }
        return valid.map { effectivePrimaryRemaining($0) }.reduce(0, +) / valid.count
    }

    /// 菜单栏显示的剩余百分比：混合模式用全部账号均值，非混合模式用优先类型账号均值
    var menuBarRemainingPercent: Int {
        guard !mixTypes, !priorityType.isEmpty else {
            return averageRemainingPercent
        }
        let filtered = accountUsages.filter { $0.type == priorityType && $0.error == nil }
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
        setupFileWatcher()
        startTimer()
        Task { await refresh() }
    }

    // MARK: - Refresh

    func refresh() async {
        isLoading = true
        let accounts = accountLoader.loadAccounts(from: accountsDirectory)
        let usages = await usageService.fetchAllUsages(for: accounts)
        accountUsages = usages.sorted { $0.email < $1.email }
        lastRefreshTime = Date()
        isLoading = false
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
                // Debounce: wait 1s after last change
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
