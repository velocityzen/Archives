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

        if tool.outputToStdout {
            return await extractToStdout(
                toolPath: toolPath, args: args, source: source, destination: destination)
        }

        return await runExtraction(toolPath: toolPath, args: args)
    }

    @concurrent
    private func runExtraction(toolPath: String, args: [String]) async -> Result<
        Void, ExtractionError
    > {
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
            .flatMap { $0.toResult() }
    }

    @concurrent
    private func extractToStdout(toolPath: String, args: [String], source: URL, destination: URL)
        async -> Result<Void, ExtractionError>
    {
        let outputFilename = source.deletingPathExtension().lastPathComponent
        let outputFileURL = destination.appendingPathComponent(outputFilename)
        let outputFilePath = FilePath(outputFileURL.path)

        return await openFileForWriting(outputFilePath)
            .flatMapAsync { outputFile in
                await Result
                    .fromAsync {
                        try await run(
                            .path(FilePath(toolPath)),
                            arguments: Arguments(args),
                            output: .fileDescriptor(outputFile, closeAfterSpawningProcess: true),
                            error: .string(limit: 4096)
                        )
                    }
                    .mapError { error in
                        try? outputFile.close()
                        return ExtractionError.fileSystemError(error)
                    }
            }
            .flatMap { $0.toResult() }
            .tapError { _ in
                removeFile(at: outputFileURL)
            }
    }

    private func openFileForWriting(_ path: FilePath) -> Result<FileDescriptor, ExtractionError> {
        Result {
            try FileDescriptor.open(
                path,
                .writeOnly,
                options: [.create, .exclusiveCreate],
                permissions: [.ownerReadWrite, .groupRead, .otherRead]
            )
        }
        .mapError { .fileSystemError($0) }
    }
}

enum ExtractionError: LocalizedError {
    case unsupportedFormat(String)
    case processError(exitCode: Int32, message: String?)
    case fileSystemError(Error)

    var errorDescription: String? {
        switch self {
            case .unsupportedFormat(let ext):
                return "Unsupported archive format: \(ext)"
            case .processError(let exitCode, let message):
                if let message = message, !message.isEmpty {
                    return message.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return "Process failed with exit code \(exitCode)"
            case .fileSystemError(let error):
                return error.localizedDescription
        }
    }
}

extension TerminationStatus {
    nonisolated var exitCode: Int32 {
        switch self {
            case .exited(let code):
                return code
            default:
                return -1
        }
    }
}

extension CollectedResult where Error.OutputType == String? {
    nonisolated func toResult() -> Result<Void, ExtractionError> {
        guard terminationStatus.isSuccess else {
            return .failure(
                .processError(
                    exitCode: terminationStatus.exitCode,
                    message: standardError
                )
            )
        }
        return .success(())
    }
}
