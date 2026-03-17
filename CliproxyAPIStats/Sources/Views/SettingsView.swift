import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case usage = "配额查询"
    case settings = "设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .usage: return "chart.bar.fill"
        case .settings: return "gearshape"
        }
    }
}

struct SettingsWindowView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedItem: SidebarItem = .usage

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 200)
        } detail: {
            switch selectedItem {
            case .usage:
                UsageDetailView(viewModel: viewModel)
            case .settings:
                SettingsDetailView(viewModel: viewModel)
            }
        }
        .frame(width: 680, height: 480)
        .onDisappear {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }
}

// MARK: - Usage Detail (right panel)

struct UsageDetailView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("配额查询")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)

                if let time = viewModel.lastRefreshTime {
                    Text(time, style: .time)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Summaries
                    ForEach(viewModel.groupSummaries) { summary in
                        UsageGroupCard(summary: summary)
                    }

                    Divider()

                    // Account list
                    ForEach(viewModel.accountUsages) { usage in
                        UsageAccountRow(usage: usage)
                    }
                }
                .padding(20)
            }
        }
    }
}

struct UsageGroupCard: View {
    let summary: GroupSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(summary.type)
                    .font(.headline)

                Text("\(summary.accountCount) 个账号")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .cornerRadius(4)

                Spacer()
            }

            HStack(spacing: 24) {
                UsageMetric(label: "5H 剩余", percent: summary.avgPrimaryRemaining)

                if let secondary = summary.avgSecondaryRemaining {
                    UsageMetric(label: "周剩余", percent: secondary)
                }
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.3))
        .cornerRadius(10)
    }
}

struct UsageMetric: View {
    let label: String
    let percent: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ProgressView(value: Double(percent), total: 100)
                    .tint(colorForPercent(percent))
                    .frame(width: 100)

                Text("\(percent)%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(colorForPercent(percent))
                    .monospacedDigit()
            }
        }
    }
}

struct UsageAccountRow: View {
    let usage: AccountUsage

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(usage.maskedEmail)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TagView(text: usage.type, color: .purple)
                    TagView(text: usage.planType, color: .teal)
                }

                if let error = usage.error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            if usage.error == nil {
                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("5H 剩余")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text("\(usage.primaryRemainingPercent)%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(colorForPercent(usage.primaryRemainingPercent))
                                .monospacedDigit()
                            Text(usage.primaryResetTime)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let secondaryRemaining = usage.secondaryRemainingPercent,
                       let resetTime = usage.secondaryResetTime {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("周剩余")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Text("\(secondaryRemaining)%")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(colorForPercent(secondaryRemaining))
                                    .monospacedDigit()
                                Text(resetTime)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Settings Detail (right panel)

struct SettingsDetailView: View {
    @ObservedObject var viewModel: AppViewModel

    private let intervals: [(label: String, seconds: Int)] = [
        ("2 min", 120),
        ("5 min", 300),
        ("10 min", 600),
    ]

    var body: some View {
        Form {
            Section("通用") {
                HStack {
                    Text("账号目录")
                    Spacer()
                    Text(viewModel.accountsDirectory)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 200)

                    Button("选择...") {
                        selectDirectory()
                    }
                    .controlSize(.small)
                }

                HStack {
                    Text("刷新间隔")
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(intervals, id: \.seconds) { interval in
                            Button(interval.label) {
                                viewModel.refreshInterval = interval.seconds
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                viewModel.refreshInterval == interval.seconds
                                    ? Color.accentColor
                                    : Color.gray.opacity(0.2)
                            )
                            .foregroundStyle(
                                viewModel.refreshInterval == interval.seconds
                                    ? .white
                                    : .primary
                            )
                            .cornerRadius(6)
                        }
                    }
                }

                Toggle("开机自启", isOn: $viewModel.launchAtLogin)
            }

            Section("计算") {
                Toggle("周限额耗尽时 5H 按 0% 计算", isOn: $viewModel.weeklyExhaustedZeroes5H)
                    .help("开启后，周限额已达 100% 的账号，其 5H 剩余以 0% 参与均值计算")
            }

            Section {
                HStack {
                    Spacer()
                    Button("退出应用") {
                        NSApplication.shared.terminate(nil)
                    }
                    .foregroundStyle(.red)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.accountsDirectory = url.path
        }
    }
}
