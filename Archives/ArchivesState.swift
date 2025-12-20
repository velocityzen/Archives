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
    private var isProcessing = false

    var currentItem: ArchiveItem? {
        items.first { $0.status == .extracting }
    }

    var pendingCount: Int {
        items.filter { $0.status == .pending }.count
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
            scheduleQuitIfComplete()
            return
        }

        isProcessing = true
        items[index].status = .extracting

        let url = items[index].url

        Task {
            let result = await extract(at: url)

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

    private func extract(at url: URL) async -> Result<String, ExtractionError> {
        let destination = url.deletingLastPathComponent()
            .appendingPathComponent(url.deletingPathExtension().lastPathComponent)

        let result = await createDestinationDirectory(destination)
            .flatMapAsync { _ in
                await ArchiveRegistry.extractor(for: url)
                    .flatMapAsync { extractor in
                        await extractor.extract(from: url, to: destination)
                    }
            }
            .map { destination.path }

        if case .success = result, deleteAfterExtraction {
            try? FileManager.default.removeItem(at: url)
        }

        return result
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

    private func scheduleQuitIfComplete() {
        guard hasCompleted && !hasErrors else { return }

        Task {
            try? await Task.sleep(for: .seconds(3))
            NSApplication.shared.terminate(nil)
        }
    }
}
