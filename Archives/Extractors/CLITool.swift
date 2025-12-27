import Foundation

nonisolated
    struct CLITool: Codable, Equatable
{
    let identifier: String
    let command: String
    let name: String
    let fileExtensions: [String]
    let contentTypes: [String]
    let arguments: [String]
    let installHint: String
    let outputToStdout: Bool
    var detectedPath: String?

    var isAvailable: Bool { detectedPath != nil }

    func buildArguments(source: String, destination: String) -> [String] {
        arguments.map { arg in
            arg.replacingOccurrences(of: "{{source}}", with: source)
                .replacingOccurrences(of: "{{destination}}", with: destination)
        }
    }

    init(
        identifier: String,
        command: String,
        name: String,
        fileExtensions: [String],
        contentTypes: [String],
        arguments: [String],
        installHint: String,
        outputToStdout: Bool = false,
        detectedPath: String? = nil
    ) {
        self.identifier = identifier
        self.command = command
        self.name = name
        self.fileExtensions = fileExtensions
        self.contentTypes = contentTypes
        self.arguments = arguments
        self.installHint = installHint
        self.outputToStdout = outputToStdout
        self.detectedPath = detectedPath
    }

    static let ditto = CLITool(
        identifier: "zip",
        command: "ditto",
        name: "ZIP Archive",
        fileExtensions: ["zip"],
        contentTypes: ["com.pkware.zip-archive", "public.zip-archive"],
        arguments: ["-xk", "{{source}}", "{{destination}}"],
        installHint: "ditto is a built-in macOS tool"
    )

    static let sevenZip = CLITool(
        identifier: "7z",
        command: "7zz",
        name: "7-Zip Archive",
        fileExtensions: ["7z"],
        contentTypes: ["org.7-zip.7-zip-archive"],
        arguments: ["x", "-y", "-o{{destination}}", "{{source}}"],
        installHint: "brew install 7-zip"
    )

    static let unrar = CLITool(
        identifier: "rar",
        command: "unrar",
        name: "RAR Archive",
        fileExtensions: ["rar"],
        contentTypes: ["com.rarlab.rar-archive"],
        arguments: ["x", "-y", "{{source}}", "{{destination}}/"],
        installHint: "brew install rar"
    )

    static let tar = CLITool(
        identifier: "tar",
        command: "tar",
        name: "Tape Archive",
        fileExtensions: ["tar"],
        contentTypes: ["public.tar-archive"],
        arguments: ["-xf", "{{source}}", "-C", "{{destination}}"],
        installHint: "tar is a built-in macOS tool"
    )

    static let tarGz = CLITool(
        identifier: "tar.gz",
        command: "tar",
        name: "Gzip Compressed Archive",
        fileExtensions: ["tar.gz", "tgz"],
        contentTypes: ["org.gnu.gnu-zip-tar-archive"],
        arguments: ["-xzf", "{{source}}", "-C", "{{destination}}"],
        installHint: "tar is a built-in macOS tool"
    )

    static let tarBz2 = CLITool(
        identifier: "tar.bz2",
        command: "tar",
        name: "Bzip2 Compressed Archive",
        fileExtensions: ["tar.bz2", "tbz2", "tbz"],
        contentTypes: ["org.bzip.bzip2-tar-archive"],
        arguments: ["-xjf", "{{source}}", "-C", "{{destination}}"],
        installHint: "tar is a built-in macOS tool"
    )

    static let tarXz = CLITool(
        identifier: "tar.xz",
        command: "tar",
        name: "XZ Compressed Archive",
        fileExtensions: ["tar.xz", "txz"],
        contentTypes: ["org.tukaani.xz-tar-archive"],
        arguments: ["-xJf", "{{source}}", "-C", "{{destination}}"],
        installHint: "tar is a built-in macOS tool"
    )

    static let gzip = CLITool(
        identifier: "gz",
        command: "gunzip",
        name: "Gzip Compressed File",
        fileExtensions: ["gz"],
        contentTypes: ["org.gnu.gnu-zip-archive"],
        arguments: ["-c", "{{source}}"],
        installHint: "gunzip is a built-in macOS tool",
        outputToStdout: true
    )

    static let bzip2 = CLITool(
        identifier: "bz2",
        command: "bunzip2",
        name: "Bzip2 Compressed File",
        fileExtensions: ["bz2"],
        contentTypes: ["public.bzip2-archive"],
        arguments: ["-c", "{{source}}"],
        installHint: "bunzip2 is a built-in macOS tool",
        outputToStdout: true
    )

    // Order matters: compound extensions first, then simple ones
    static let allTools: [CLITool] = [
        .tarGz, .tarBz2, .tarXz,
        .ditto, .sevenZip, .unrar, .tar, .gzip, .bzip2,
    ]
}

class CLIToolRegistry {
    static let shared = CLIToolRegistry()

    private let defaults = UserDefaults.standard
    private let detectedToolsKey = "detectedCLITools"
    private let hasScannedKey = "hasScannedCLITools"

    private(set) var tools: [String: CLITool] = [:]

    private init() {
        loadFromDefaults()
    }

    var hasScanned: Bool {
        defaults.bool(forKey: hasScannedKey)
    }

    func scanIfNeeded() {
        guard !hasScanned else { return }
        scan()
    }

    func scan() {
        let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
        var searchPaths = path.split(separator: ":").map(String.init)
        // Add common paths that might not be in PATH for GUI apps
        let commonPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
        ]
        for p in commonPaths where !searchPaths.contains(p) {
            searchPaths.append(p)
        }

        for var tool in CLITool.allTools {
            tool.detectedPath = findExecutable(named: tool.command, in: searchPaths)
            tools[tool.identifier] = tool
        }

        saveToDefaults()
        defaults.set(true, forKey: hasScannedKey)
    }

    func tool(for identifier: String) -> CLITool? {
        tools[identifier]
    }

    func path(for identifier: String) -> String? {
        tools[identifier]?.detectedPath
    }

    private func loadFromDefaults() {
        guard let data = defaults.data(forKey: detectedToolsKey),
            let decoded = try? JSONDecoder().decode([String: CLITool].self, from: data)
        else {
            return
        }
        tools = decoded
    }

    private func saveToDefaults() {
        guard let data = try? JSONEncoder().encode(tools) else { return }
        defaults.set(data, forKey: detectedToolsKey)
    }
}
