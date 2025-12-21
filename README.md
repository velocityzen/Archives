# Archives

A lightweight macOS app for extracting archives. Drop files onto the window or double-click to extract.

## Supported Formats

| Format | Extensions | Tool | Built-in |
|--------|------------|------|----------|
| ZIP | `.zip` | ditto | Yes |
| TAR | `.tar` | tar | Yes |
| Gzip TAR | `.tar.gz`, `.tgz` | tar | Yes |
| Bzip2 TAR | `.tar.bz2`, `.tbz2`, `.tbz` | tar | Yes |
| XZ TAR | `.tar.xz`, `.txz` | tar | Yes |
| Gzip | `.gz` | gunzip | Yes |
| Bzip2 | `.bz2` | bunzip2 | Yes |
| 7-Zip | `.7z` | 7zz | No |
| RAR | `.rar` | unrar | No |

## Installing Optional Tools

For 7-Zip and RAR support, install the CLI tools via Homebrew:

```bash
brew install 7-zip
brew install rar
```

The app automatically detects available tools on first launch.

## Building

Open `Archives.xcodeproj` in Xcode and build.

## Adding New File Formats

To add support for a new archive format:

### 1. Add the CLI tool definition in `CLITool.swift`

```swift
static let myFormat = CLITool(
    identifier: "myformat",           // Unique identifier
    command: "myextractor",           // CLI command name
    name: "My Format Archive",        // Display name
    fileExtensions: ["myf", "myformat"], // Supported extensions
    contentTypes: ["com.example.myformat"], // UTI content types
    arguments: ["-x", "{{source}}", "-o", "{{destination}}"], // CLI arguments
    installHint: "brew install myextractor", // Installation instructions
    outputToStdout: false             // Set true if tool outputs to stdout
)
```

Add the new tool to the `allTools` array. Order matters: compound extensions (like `.tar.gz`) should come before simple ones (like `.gz`).

For tools that output to stdout (like `gunzip -c`), set `outputToStdout: true`. The app will capture stdout and write it to a file.

### 2. Update `Info.plist`

Add a document type entry:

```xml
<dict>
    <key>CFBundleTypeName</key>
    <string>My Format Archive</string>
    <key>CFBundleTypeRole</key>
    <string>Viewer</string>
    <key>LSHandlerRank</key>
    <string>Alternate</string>
    <key>LSItemContentTypes</key>
    <array>
        <string>com.example.myformat</string>
    </array>
</dict>
```

If the UTI is not a system-defined type, add a `UTImportedTypeDeclarations` entry:

```xml
<dict>
    <key>UTTypeIdentifier</key>
    <string>com.example.myformat</string>
    <key>UTTypeDescription</key>
    <string>My Format Archive</string>
    <key>UTTypeConformsTo</key>
    <array>
        <string>public.data</string>
        <string>public.archive</string>
    </array>
    <key>UTTypeTagSpecification</key>
    <dict>
        <key>public.filename-extension</key>
        <array>
            <string>myf</string>
            <string>myformat</string>
        </array>
        <key>public.mime-type</key>
        <string>application/x-myformat</string>
    </dict>
</dict>
```

## License

MIT
