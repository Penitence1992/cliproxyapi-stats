import SwiftUI

struct AccountListSection: View {
    let usages: [AccountUsage]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("账号详情")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            if usages.isEmpty {
                Text("暂无账号")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(usages) { usage in
                    AccountCard(usage: usage)
                }
            }
        }
        .padding(16)
    }
}

struct AccountCard: View {
    let usage: AccountUsage

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(usage.maskedEmail)
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                HStack(spacing: 4) {
                    TagView(text: usage.type, color: .purple)
                    TagView(text: usage.planType, color: .teal)
                }
            }

            if let error = usage.error {
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
