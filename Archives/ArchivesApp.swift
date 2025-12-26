import SwiftUI

@main
struct ArchivesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var state = ArchivesState()

    init() {
        CLIToolRegistry.shared.scanIfNeeded()
    }

    var body: some Scene {
        Window("Archives", id: "main") {
            ArchiveView(state: state)
                .onAppear {
                    appDelegate.state = state
                }
                .onOpenURL { url in
                    state.enqueue(url)
                }
        }
        .windowResizability(.contentSize)
        .commands {
          CommandGroup(after: .appInfo) {
            CheckForUpdatesView()
          }
        }

        Settings {
            SettingsView()
        }
    }
}
