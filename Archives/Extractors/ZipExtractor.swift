import FP
import Foundation
import Subprocess
import System

struct ZipExtractor: ArchiveExtractor {
    static let identifier = "zip"
    static let name = "ZIP Archive"
    static let fileExtensions = ["zip"]
    static let contentTypes = [
        "com.pkware.zip-archive",
        "public.zip-archive",
    ]

    func extract(from source: URL, to destination: URL) async -> Result<Void, ExtractionError> {
        await Result
            .fromAsync {
                try await run(
                    .path("/usr/bin/ditto"),
                    arguments: ["-xk", source.path, destination.path],
                    output: .discarded,
                    error: .string(limit: 4096)
                )
            }
            .mapError { .processError(exitCode: 1, message: $0.localizedDescription) }
            .flatMap { result in
                guard result.terminationStatus.isSuccess else {
                    return .failure(
                        .processError(
                            exitCode: result.terminationStatus.exitCode,
                            message: result.standardError
                        ))
                }
                return .success(())
            }
    }
}

extension TerminationStatus {
    fileprivate var exitCode: Int32 {
        switch self {
        case .exited(let code):
            return code
        default:
            return -1
        }
    }
}
