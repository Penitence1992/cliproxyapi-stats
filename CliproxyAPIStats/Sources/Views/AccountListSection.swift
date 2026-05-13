import SwiftUI

struct AccountListSection: View {
    private let usageGroups: [AccountUsageGroup]
    var onRefreshAccount: ((String) -> Void)?

    init(usages: [AccountUsage], onRefreshAccount: ((String) -> Void)? = nil) {
        self.usageGroups = Self.makeUsageGroups(usages)
        self.onRefreshAccount = onRefreshAccount
    }

    private static func makeUsageGroups(_ usages: [AccountUsage]) -> [AccountUsageGroup] {
        var suspectedBanned: [AccountUsage] = []
        var regular: [AccountUsage] = []
        var free: [AccountUsage] = []
        suspectedBanned.reserveCapacity(usages.count)
        regular.reserveCapacity(usages.count)
        free.reserveCapacity(usages.count)

        for usage in usages {
            if usage.isSuspectedBanned {
                suspectedBanned.append(usage)
            } else if usage.isFreePlan {
                free.append(usage)
            } else {
                regular.append(usage)
            }
        }

        var groups: [AccountUsageGroup] = []
        if !regular.isEmpty {
            groups.append(AccountUsageGroup(title: "非 Free 账号", usages: regular))
        }
        if !free.isEmpty {
            groups.append(AccountUsageGroup(title: "Free 账号", usages: free))
        }
        if !suspectedBanned.isEmpty {
            groups.append(AccountUsageGroup(title: "*疑似封禁*", usages: suspectedBanned))
        }
        return groups
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            Text("账号详情")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            if usageGroups.isEmpty {
                Text("暂无账号")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(usageGroups) { group in
                    AccountUsageGroupView(group: group, onRefreshAccount: onRefreshAccount)
                }
            }
        }
        .padding(16)
    }
}

private struct AccountUsageGroup: Identifiable {
    let title: String
    let usages: [AccountUsage]

    var id: String { title }
}

private struct AccountUsageGroupView: View {
    let group: AccountUsageGroup
    var onRefreshAccount: ((String) -> Void)?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(group.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text("\(group.usages.count) 个")
                    .font(.system(size: 10))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.quaternary)
                    .cornerRadius(4)
            }

            ForEach(group.usages) { usage in
                AccountCard(usage: usage, onRefresh: onRefreshAccount)
            }
        }
    }
}

struct AccountCard: View {
    let usage: AccountUsage
    var onRefresh: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(usage.email)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                HStack(spacing: 4) {
                    TagView(text: usage.type, color: .purple)
                    if !usage.isLoading && !usage.planType.isEmpty {
                        TagView(text: usage.planType, color: .teal)
                    }

                    if let onRefresh {
                        Button {
                            onRefresh(usage.id)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(usage.isLoading)
                    }
                }
            }

            if usage.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            } else if let error = usage.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Spacer()
                }
            } else {
                AccountUsageRow(
                    label: "5H",
                    remainingPercent: usage.primaryRemainingPercent,
                    resetTime: usage.primaryResetTime
                )

                if let secondaryRemaining = usage.secondaryRemainingPercent,
                   let resetTime = usage.secondaryResetTime {
                    AccountUsageRow(
                        label: "周",
                        remainingPercent: secondaryRemaining,
                        resetTime: resetTime
                    )
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5))
        .cornerRadius(8)
    }
}

struct AccountUsageRow: View {
    let label: String
    let remainingPercent: Int
    let resetTime: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 45, alignment: .leading)

            ProgressView(value: Double(remainingPercent), total: 100)
                .tint(colorForPercent(remainingPercent))
                .frame(width: 100)

            Text("\(remainingPercent)%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(colorForPercent(remainingPercent))
                .monospacedDigit()
                .frame(width: 30, alignment: .trailing)

            Text("重置 \(resetTime)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }
}

struct TagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10))
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
}
