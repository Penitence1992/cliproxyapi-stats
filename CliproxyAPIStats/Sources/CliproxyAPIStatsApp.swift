import SwiftUI

@main
struct CliproxyAPIStatsApp: App {
    @StateObject private var viewModel = AppViewModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)

        Window("CliproxyAPI Stats", id: "settings") {
            SettingsWindowView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
