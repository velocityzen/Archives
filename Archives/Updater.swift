import Sparkle
import SwiftUI

// A simple view for the "Check for Updates..." menu item
struct CheckForUpdatesView: View {
  @State private var checkForUpdatesViewModel = CheckForUpdatesViewModel()

  var body: some View {
    Button("Check for Updates…", action: checkForUpdatesViewModel.checkForUpdates)
      .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
  }
}

// View model for the update checker
@Observable
final class CheckForUpdatesViewModel {
  var canCheckForUpdates = false

  private let updaterController: SPUStandardUpdaterController
  private var observation: NSKeyValueObservation?

  init() {
    // Create the updater controller
    self.updaterController = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )

    // Observe the updater's canCheckForUpdates property using KVO
    observation = updaterController.updater.observe(\.canCheckForUpdates, options: [.new, .initial]) { [weak self] _, change in
      guard let self else { return }
      Task { @MainActor in
        self.canCheckForUpdates = change.newValue ?? false
      }
    }
  }

  deinit {
    observation?.invalidate()
  }

  func checkForUpdates() {
    updaterController.updater.checkForUpdates()
  }
}
