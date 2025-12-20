import FP
import SwiftUI

@main
struct ArchivesApp: App {
    @State private var extractionState = ExtractionState()

    var body: some Scene {
        WindowGroup {
            ContentView(state: extractionState)
                .onOpenURL { url in
                    Task {
                        await extractionState.extract(at: url)
                    }
                }
        }
        .windowResizability(.contentSize)
    }
}

@Observable
@MainActor
class ExtractionState {
    var status: ExtractionStatus = .idle

    func extract(at url: URL) async {
        status = .extracting(filename: url.lastPathComponent)

        let destination = url.deletingLastPathComponent()
            .appendingPathComponent(url.deletingPathExtension().lastPathComponent)

        let result = await createDestinationDirectory(destination)
            .flatMapAsync { _ in
                await ExtractorRegistry.extractor(for: url)
                    .flatMapAsync { extractor in
                        await extractor.extract(from: url, to: destination)
                    }
            }

        switch result {
        case .success:
            status = .success(destination: destination.path)
            try? await Task.sleep(for: .seconds(1.5))
            NSApplication.shared.terminate(nil)

        case .failure(let error):
            status = .error(error.localizedDescription)
        }
    }

    private func createDestinationDirectory(_ destination: URL) -> Result<Void, ExtractionError> {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: destination.path) else {
            return .success(())
        }

        do {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
            return .success(())
        } catch {
            return .failure(.fileSystemError(error.localizedDescription))
        }
    }
}

enum ExtractionStatus: Equatable {
    case idle
    case extracting(filename: String)
    case success(destination: String)
    case error(String)
}
