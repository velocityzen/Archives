import FP
import Foundation
import Subprocess
import System

struct CLIExtractor {
    let tool: CLITool

    var identifier: String { tool.identifier }
    var name: String { tool.name }
    var fileExtensions: [String] { tool.fileExtensions }
    var contentTypes: [String] { tool.contentTypes }

    func canHandle(filename: String) -> Bool {
        let lowercased = filename.lowercased()
        return fileExtensions.contains { lowercased.hasSuffix(".\($0)") }
    }

    func extract(from source: URL, to destination: URL) async -> Result<Void, ExtractionError> {
        guard let toolPath = tool.detectedPath else {
            return .failure(
                .processError(
                    exitCode: -1,
                    message: "\(tool.identifier) not found. Install with: \(tool.installHint)"
                )
            )
        }

        let args = tool.buildArguments(source: source.path, destination: destination.path)

        return
            await Result
            .fromAsync {
                try await run(
                    .path(FilePath(toolPath)),
                    arguments: Arguments(args),
                    output: .discarded,
                    error: .string(limit: 4096)
                )
            }
            .mapError {
                ExtractionError.processError(exitCode: 1, message: $0.localizedDescription)
            }
            .flatMap { result in
                guard result.terminationStatus.isSuccess else {
                    return .failure(
                        .processError(
                            exitCode: result.terminationStatus.exitCode,
                            message: result.standardError
                        )
                    )
                }
                return .success(())
            }
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

extension TerminationStatus {
    var exitCode: Int32 {
        switch self {
            case .exited(let code):
                return code
            default:
                return -1
        }
    }
}
