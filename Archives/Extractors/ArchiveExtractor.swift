import Foundation

protocol ArchiveExtractor {
    static var identifier: String { get }
    static var name: String { get }
    static var fileExtensions: [String] { get }
    static var contentTypes: [String] { get }

    func extract(from source: URL, to destination: URL) async -> Result<Void, ExtractionError>
}

extension ArchiveExtractor {
    static func canHandle(extension ext: String) -> Bool {
        fileExtensions.contains(ext.lowercased())
    }

    static func canHandle(contentType: String) -> Bool {
        contentTypes.contains(contentType)
    }
}

enum ExtractionError: LocalizedError, Equatable {
    case unsupportedFormat(String)
    case processError(exitCode: Int32, message: String?)
    case fileSystemError(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "Unsupported archive format: \(ext)"
        case .processError(let exitCode, let message):
            if let message = message, !message.isEmpty {
                return message.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return "Process failed with exit code \(exitCode)"
        case .fileSystemError(let message):
            return message
        }
    }
}
