import SwiftUI

struct SummarySection: View {
    let summaries: [GroupSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("汇总")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            if summaries.isEmpty {
                Text("暂无数据")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(summaries) { summary in
                    GroupCard(summary: summary)
                }
            }
        }
        .padding(16)
    }
}

struct GroupCard: View {
    let summary: GroupSummary

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(summary.type)
                    .fontWeight(.semibold)
                    .font(.subheadline)

                Text("\(summary.accountCount) 个账号")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .cornerRadius(4)

                Spacer()
            }

            UsageRow(label: "5H 剩余", percent: summary.avgPrimaryRemaining)

            if let secondary = summary.avgSecondaryRemaining {
                UsageRow(label: "周剩余", percent: secondary)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5))
        .cornerRadius(8)
    }
}

struct UsageRow: View {
    let label: String
    let percent: Int

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            ProgressView(value: Double(percent), total: 100)
                .tint(colorForPercent(percent))
                .frame(width: 120)

            Text("\(percent)%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(colorForPercent(percent))
                .monospacedDigit()
                .frame(width: 36, alignment: .trailing)
        }
    }
}

func colorForPercent(_ remaining: Int) -> Color {
    let used = 100 - remaining
    if used > 80 { return .red }
    if used > 50 { return .yellow }
    return .green
}
