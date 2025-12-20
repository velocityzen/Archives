import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var state: ExtractionState
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            switch state.status {
            case .idle:
                Image(systemName: "doc.zipper")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Drop a zip file or double-click to extract")
                    .foregroundStyle(.secondary)

            case .extracting(let filename):
                ProgressView()
                    .scaleEffect(1.5)
                Text("Extracting \(filename)...")
                    .foregroundStyle(.primary)

            case .success(let destination):
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("Extracted successfully")
                    .foregroundStyle(.primary)
                Text(destination)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)

            case .error(let message):
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text("Extraction failed")
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(minWidth: 300, minHeight: 200)
        .background(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
        )
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            guard ExtractorRegistry.isSupported(url: url) else { return false }

            Task {
                await state.extract(at: url)
            }
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
}

#Preview {
    ContentView(state: ExtractionState())
}
