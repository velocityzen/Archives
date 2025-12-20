import SwiftUI

struct ArchiveView: View {
    var state: ArchivesState
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            if state.items.isEmpty {
                idleView
            } else {
                queueView
                .safeAreaPadding(.top, 28)
            }
        }
        .frame(minWidth: 250, minHeight: 200)
        .background {
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow
            )
            .overlay(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: isTargeted)
        }
        .ignoresSafeArea(.all)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .toolbar(removing: .title)
        .dropDestination(for: URL.self) { urls, _ in
            let supportedUrls = urls.filter { ArchiveRegistry.isSupported(url: $0) }
            guard !supportedUrls.isEmpty else { return false }
            state.enqueue(supportedUrls)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }

    private var idleView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .scaleEffect(isTargeted ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
            Text("Drop archives to extract")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private var queueView: some View {
        VStack(spacing: 0) {
            if let current = state.currentItem {
                currentItemView(current)
                    .padding()
            }

            if state.items.count > 1 {
                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(state.items.filter { $0.status != .extracting }) { item in
                            queueItemRow(item)
                            Divider()
                        }
                    }
                }
            }

            if state.hasCompleted && !state.hasErrors {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("All files extracted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }

    private func currentItemView(_ item: ArchiveItem) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Extracting \(item.filename)")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)

            if state.pendingCount > 0 {
                Text("\(state.pendingCount) more in queue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func queueItemRow(_ item: ArchiveItem) -> some View {
        HStack(spacing: 12) {
            statusIcon(for: item.status)

            Text(item.filename)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            statusLabel(for: item.status)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func statusIcon(for status: ArchiveItem.ItemStatus) -> some View {
        switch status {
            case .pending:
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
            case .extracting:
                ProgressView()
                    .scaleEffect(0.6)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private func statusLabel(for status: ArchiveItem.ItemStatus) -> some View {
        switch status {
            case .pending:
                Text("Pending")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .extracting:
                Text("Extracting...")
                    .font(.caption)
                    .foregroundStyle(.blue)
            case .success:
                Text("Done")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .error(let message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
        }
    }
}

#Preview("Empty State") {
    ArchiveView(state: ArchivesState())
}

#Preview("Single Item Extracting") {
    let state = ArchivesState()
    state.items = [
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/archive.zip"),
            status: .extracting
        )
    ]
    return ArchiveView(state: state)
}

#Preview("Multiple Items in Queue") {
    let state = ArchivesState()
    state.items = [
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/photos.zip"),
            status: .extracting
        ),
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/documents.zip"),
            status: .pending
        ),
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/videos.zip"),
            status: .pending
        ),
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/music.zip"),
            status: .pending
        ),
    ]
    return ArchiveView(state: state)
}

#Preview("All Completed Successfully") {
    let state = ArchivesState()
    state.items = [
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/archive1.zip"),
            status: .success(destination: "/Users/test/Downloads/archive1")
        ),
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/archive2.zip"),
            status: .success(destination: "/Users/test/Downloads/archive2")
        ),
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/archive3.zip"),
            status: .success(destination: "/Users/test/Downloads/archive3")
        ),
    ]
    return ArchiveView(state: state)
}

#Preview("With Errors") {
    let state = ArchivesState()
    state.items = [
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/success.zip"),
            status: .success(destination: "/Users/test/Downloads/success")
        ),
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/corrupted.zip"),
            status: .error("Archive is corrupted or invalid")
        ),
        ArchiveItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/pending.zip"),
            status: .pending
        ),
    ]
    return ArchiveView(state: state)
}

#Preview("Long Filename") {
    let state = ArchivesState()
    state.items = [
        ArchiveItem(
            url: URL(
                fileURLWithPath:
                    "/Users/test/Downloads/this-is-a-very-long-filename-that-should-be-truncated-in-the-middle.zip"
            ),
            status: .extracting
        )
    ]
    return ArchiveView(state: state)
}

#Preview("Large Queue") {
    let state = ArchivesState()
    state.items =
        [
            ArchiveItem(
                url: URL(fileURLWithPath: "/Users/test/Downloads/current.zip"),
                status: .extracting
            )
        ]
        + (1...10).map { i in
            ArchiveItem(
                url: URL(fileURLWithPath: "/Users/test/Downloads/file\(i).zip"),
                status: .pending
            )
        }
    return ArchiveView(state: state)
}
