import SwiftUI

struct SettingsView: View {
    @AppStorage("deleteAfterExtraction") private var deleteAfterExtraction = false
    @AppStorage("quitAfterExtraction") private var quitAfterExtraction = false
    @State private var tools: [CLITool] = []

    var body: some View {
        Form {
            Section("After successful extraction") {
                Toggle("Delete archive", isOn: $deleteAfterExtraction)
                Toggle("Quit app", isOn: $quitAfterExtraction)
            }

            Section("Detected Tools") {
                ForEach(tools, id: \.identifier) { tool in
                    ToolRow(tool: tool)
                }

                Button("Refresh") {
                    CLIToolRegistry.shared.scan()
                    loadTools()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .onAppear {
            loadTools()
        }
    }

    private func loadTools() {
        tools = CLITool.allTools.map { tool in
            CLIToolRegistry.shared.tool(for: tool.identifier) ?? tool
        }
    }
}

struct ToolRow: View {
    let tool: CLITool

    var body: some View {
        HStack {
            Image(systemName: tool.isAvailable ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(tool.isAvailable ? .green : .secondary)

            VStack(alignment: .leading) {
                Text(tool.name)
                if let path = tool.detectedPath {
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(tool.installHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !tool.isAvailable {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(tool.installHint, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy install command")
            }
        }
    }
}

#Preview {
    SettingsView()
}
