import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var state: ArchivesState?

    func application(_ application: NSApplication, open urls: [URL]) {
        state?.enqueue(urls)
    }
}
