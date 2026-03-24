import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        HStack(spacing: 4) {
            menuBarIcon
            Text("\(viewModel.menuBarRemainingPercent)%")
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var menuBarIcon: some View {
        if !viewModel.mixTypes, !viewModel.priorityType.isEmpty,
           let nsImage = providerIcon(for: viewModel.priorityType) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
        } else {
            Image(systemName: "chart.bar.fill")
        }
    }

    private func providerIcon(for type: String) -> NSImage? {
        guard let url = Bundle.module.url(
            forResource: "ProviderIcon-\(type.lowercased())",
            withExtension: "svg"
        ) else { return nil }
        return NSImage(contentsOf: url)
    }
}
