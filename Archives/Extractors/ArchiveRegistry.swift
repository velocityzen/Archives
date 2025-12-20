import FP
import Foundation

struct ArchiveRegistry {
    static var extractors: [CLIExtractor] {
        // Preserve order from allTools (compound extensions first)
        CLITool.allTools.compactMap { tool in
            guard let detected = CLIToolRegistry.shared.tool(for: tool.identifier),
                detected.isAvailable
            else {
                return nil
            }
            return CLIExtractor(tool: detected)
        }
    }

    static func extractor(for url: URL) -> Result<CLIExtractor, ExtractionError> {
        let filename = url.lastPathComponent
        return .fromOptional(
            extractors.first { $0.canHandle(filename: filename) },
            error: .unsupportedFormat(url.pathExtension)
        )
    }

    static var supportedExtensions: [String] {
        extractors.flatMap { $0.fileExtensions }
    }

    static var supportedContentTypes: [String] {
        extractors.flatMap { $0.contentTypes }
    }

    static func isSupported(url: URL) -> Bool {
        let filename = url.lastPathComponent
        return extractors.contains { $0.canHandle(filename: filename) }
    }
}
