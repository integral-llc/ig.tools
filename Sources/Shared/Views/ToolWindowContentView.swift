import SwiftUI

/// Wraps a tool's view and adds a gear button for the settings popover.
struct ToolWindowContentView: View {
    let tool: any Tool
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            tool.makeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                Spacer()
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                    tool.makeSettingsView()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}
