import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.bar.fill")
            Text("\(viewModel.averageRemainingPercent)%")
                .monospacedDigit()
        }
    }
}
