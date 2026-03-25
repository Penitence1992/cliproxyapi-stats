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
                .renderingMode(.template)
        } else {
            Image(systemName: "chart.bar.fill")
        }
    }

    private func providerIcon(for type: String) -> NSImage? {
        guard let url = Bundle.main.url(
            forResource: "ProviderIcon-\(type.lowercased())",
            withExtension: "svg"
        ) else { return nil }
        guard let image = NSImage(contentsOf: url) else { return nil }
        image.size = NSSize(width: 14, height: 14)
        return image
    }
}
