import FP
import Foundation

struct ExtractorRegistry {
    private static let extractors: [any ArchiveExtractor] = [
        ZipExtractor()
    ]

    static func extractor(for url: URL) -> Result<any ArchiveExtractor, ExtractionError> {
        let ext = url.pathExtension
        return .fromOptional(
            extractors.first { type(of: $0).canHandle(extension: ext) },
            error: .unsupportedFormat(ext)
        )
    }

    static var supportedExtensions: [String] {
        extractors.flatMap { type(of: $0).fileExtensions }
    }

    static var supportedContentTypes: [String] {
        extractors.flatMap { type(of: $0).contentTypes }
    }

    static func isSupported(url: URL) -> Bool {
        let ext = url.pathExtension
        return extractors.contains { type(of: $0).canHandle(extension: ext) }
    }
}
