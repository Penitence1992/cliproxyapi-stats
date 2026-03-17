import SwiftUI

struct FooterView: View {
    @ObservedObject var viewModel: AppViewModel

    private var formattedTime: String {
        guard let time = viewModel.lastRefreshTime else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: time)
    }

    private var intervalLabel: String {
        switch viewModel.refreshInterval {
        case 120: return "2 min"
        case 300: return "5 min"
        case 600: return "10 min"
        default: return "\(viewModel.refreshInterval)s"
        }
    }

    var body: some View {
        HStack {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                Text("刷新中...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("上次刷新: \(formattedTime)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text("间隔: \(intervalLabel)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
