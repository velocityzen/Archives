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
| 7-Zip | `.7z` | 7zz | No |
| RAR | `.rar` | unrar | No |

## Installing Optional Tools

For 7-Zip and RAR support, install the CLI tools via Homebrew:

```bash
brew install 7zip
brew install unrar
```

The app automatically detects available tools on first launch.

## Building

Open `Archives.xcodeproj` in Xcode and build.

## License

MIT
