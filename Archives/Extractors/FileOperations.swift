import Foundation

nonisolated func fileExists(at url: URL) -> Bool {
    FileManager.default.fileExists(atPath: url.path)
}

nonisolated func uniqueDestination(for url: URL) -> URL {
    guard fileExists(at: url) else {
        return url
    }

    let directory = url.deletingLastPathComponent()
    let filename = url.lastPathComponent

    var counter = 1
    while true {
        let newName = "\(filename) \(counter)"
        let newPath = directory.appendingPathComponent(newName)
        if !fileExists(at: newPath) {
            return newPath
        }
        counter += 1
    }
}

nonisolated func createDirectory(at url: URL) -> Result<Void, ExtractionError> {
    do {
        try FileManager.default.createDirectory(
            at: url, withIntermediateDirectories: true)
        return .success(())
    } catch {
        return .failure(.fileSystemError(error))
    }
}

nonisolated func removeFile(at url: URL) -> Result<Void, ExtractionError> {
    do {
        try FileManager.default.removeItem(at: url)
        return .success(())
    } catch {
        return .failure(.fileSystemError(error))
    }
}

nonisolated func findExecutable(named command: String, in searchPaths: [String]) -> String? {
    let fileManager = FileManager.default
    for dir in searchPaths {
        let path = (dir as NSString).appendingPathComponent(command)
        if fileManager.isExecutableFile(atPath: path) {
            return path
        }
    }
    return nil
}
