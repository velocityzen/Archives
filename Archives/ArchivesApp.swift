import SwiftUI

@main
struct ArchivesApp: App {
    @State private var state = ArchivesState()

    init() {
        CLIToolRegistry.shared.scanIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ArchiveView(state: state)
                .onOpenURL { url in
                    state.enqueue(url)
                }
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}
