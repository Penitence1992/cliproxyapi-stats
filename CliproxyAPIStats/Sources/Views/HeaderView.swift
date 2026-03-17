import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack {
            Label("CliproxyAPI Stats", systemImage: "chart.bar.fill")
                .font(.headline)

            Spacer()

            HStack(spacing: 6) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(
                            viewModel.isLoading
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: viewModel.isLoading
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)

                Button {
                    NSApplication.shared.setActivationPolicy(.regular)
                    openWindow(id: "settings")
                    NSApplication.shared.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
