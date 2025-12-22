import FP
import SwiftUI

struct ArchiveItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var status: ItemStatus

    var filename: String { url.lastPathComponent }

    enum ItemStatus: Equatable {
        case pending
        case extracting
        case success(destination: String)
        case error(String)
    }
}

@Observable
@MainActor
class ArchivesState {
    var items: [ArchiveItem] = []
    @ObservationIgnored @AppStorage("deleteAfterExtraction") var deleteAfterExtraction = false
    @ObservationIgnored @AppStorage("quitAfterExtraction") var quitAfterExtraction = true
    private var isProcessing = false

    var currentItem: ArchiveItem? {
        items.first { $0.status == .extracting }
    }

    var pendingCount: Int {
        items.filter { $0.status == .pending }.count
    }

    var hasMutliple: Bool {
        items.count > 1
    }

    var hasCompleted: Bool {
        !items.isEmpty
            && items.allSatisfy {
                if case .success = $0.status { return true }
                if case .error = $0.status { return true }
                return false
            }
    }

    var hasErrors: Bool {
        items.contains {
            if case .error = $0.status { return true }
            return false
        }
    }

    func enqueue(_ url: URL) {
        guard ArchiveRegistry.isSupported(url: url) else { return }
        guard !items.contains(where: { $0.url == url }) else { return }

        items.append(ArchiveItem(url: url, status: .pending))
        processQueue()
    }

    func enqueue(_ urls: [URL]) {
        for url in urls {
            enqueue(url)
        }
    }

    private func processQueue() {
        guard !isProcessing else { return }
        guard let index = items.firstIndex(where: { $0.status == .pending }) else {
            didProcessQueue()
            return
        }

        isProcessing = true
        items[index].status = .extracting

        let url = items[index].url

        Task {
            let result = await extract(
                at: url,
                deleteAfterExtraction: deleteAfterExtraction
            )

            if let currentIndex = items.firstIndex(where: { $0.url == url }) {
                switch result {
                    case .success(let destination):
                        items[currentIndex].status = .success(destination: destination)
                    case .failure(let error):
                        items[currentIndex].status = .error(error.localizedDescription)
                }
            }

            isProcessing = false
            processQueue()
        }
    }

    @concurrent
    private func extract(at url: URL, deleteAfterExtraction: Bool) async -> Result<
        String, ExtractionError
    > {
        let extractor = await Task { @MainActor in
            ArchiveRegistry.extractor(for: url)
        }.value

        let basePath = url.deletingLastPathComponent()
            .appendingPathComponent(url.deletingPathExtension().lastPathComponent)
        let destination = uniqueDestination(for: basePath)

        return await createDestinationDirectory(destination)
            .flatMapAsync {
                await Task { @MainActor in
                    ArchiveRegistry.extractor(for: url)
                }.value
            }
            .flatMapAsync { extractor in
                await extractor.extract(from: url, to: destination)
            }
            .tap {
                if deleteAfterExtraction {
                    removeFile(url)
                } else {
                    .success(())
                }
            }
            .map { destination.path }
    }

    nonisolated
        private func uniqueDestination(for url: URL) -> URL
    {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            return url
        }

        let directory = url.deletingLastPathComponent()
        let filename = url.lastPathComponent

        var counter = 1
        while true {
            let newName = "\(filename) \(counter)"
            let newPath = directory.appendingPathComponent(newName)
            if !fileManager.fileExists(atPath: newPath.path) {
                return newPath
            }
            counter += 1
        }
    }

    nonisolated
        private func createDestinationDirectory(_ destination: URL) -> Result<Void, ExtractionError>
    {
        do {
            try FileManager.default.createDirectory(
                at: destination, withIntermediateDirectories: true)
            return .success(())
        } catch {
            return .failure(.fileSystemError(error.localizedDescription))
        }
    }

    nonisolated
        private func removeFile(_ url: URL) -> Result<Void, ExtractionError>
    {
        do {
            try FileManager.default.removeItem(at: url)
            return .success(())
        } catch {
            return .failure(.fileSystemError(error.localizedDescription))
        }
    }

    private var isSettingsWindowOpen: Bool {
        NSApplication.shared.windows.contains {
            $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window"
        }
    }

    private func didProcessQueue() {
        guard quitAfterExtraction && hasCompleted && !hasErrors && !isSettingsWindowOpen else {
            return
        }

        Task {
            try? await Task.sleep(for: .seconds(3))
            NSApplication.shared.terminate(nil)
        }
    }
}
