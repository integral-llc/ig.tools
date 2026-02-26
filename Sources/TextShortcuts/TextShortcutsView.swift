import SwiftUI

struct TextShortcutsView: View {
    @Bindable var state: TextShortcutsState
    @State private var selectedID: UUID?

    var body: some View {
        HSplitView {
            sidebarPanel
                .frame(minWidth: 160, idealWidth: 180, maxWidth: 240)
            detailPanel
                .frame(minWidth: 280, maxWidth: .infinity)
        }
    }

    // MARK: - Sidebar

    private var sidebarPanel: some View {
        VStack(spacing: 0) {
            sidebarToolbar
            Divider()
            sidebarList
        }
        .background(Color.primary.opacity(0.02))
    }

    private var sidebarToolbar: some View {
        HStack {
            Toggle("", isOn: $state.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()

            Spacer()

            accessibilityIndicator

            Button {
                let shortcut = state.addShortcut()
                selectedID = shortcut.id
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var sidebarList: some View {
        List(selection: $selectedID) {
            ForEach(state.shortcuts) { shortcut in
                ShortcutSidebarRow(shortcut: shortcut)
                    .tag(shortcut.id)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var accessibilityIndicator: some View {
        if state.isAccessibilityGranted {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
                .font(.caption)
                .help("Accessibility access granted")
        } else {
            Button {
                state.requestAccessibility()
            } label: {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Click to request accessibility access")
        }
    }

    // MARK: - Detail

    private var detailPanel: some View {
        Group {
            if let selectedID,
               let index = state.shortcuts.firstIndex(where: { $0.id == selectedID }) {
                ShortcutDetailView(
                    shortcut: $state.shortcuts[index],
                    onDelete: { deleteShortcut(at: index) }
                )
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "text.cursor")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Select a shortcut or click + to create one")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func deleteShortcut(at index: Int) {
        state.removeShortcut(state.shortcuts[index])
        if state.shortcuts.isEmpty {
            selectedID = nil
        } else if index < state.shortcuts.count {
            selectedID = state.shortcuts[index].id
        } else {
            selectedID = state.shortcuts.last?.id
        }
    }
}

// MARK: - Sidebar row

private struct ShortcutSidebarRow: View {
    let shortcut: TextShortcut

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.trigger.isEmpty ? "New Shortcut" : shortcut.trigger)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .foregroundStyle(shortcut.trigger.isEmpty ? .tertiary : .primary)

                if !shortcut.replacement.isEmpty {
                    Text(shortcut.replacement)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !shortcut.isEnabled {
                Image(systemName: "pause.circle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
        .opacity(shortcut.isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Detail view

private struct ShortcutDetailView: View {
    @Binding var shortcut: TextShortcut
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            detailToolbar
            Divider()
            detailContent
            Spacer()
        }
    }

    private var detailToolbar: some View {
        HStack {
            Toggle("Enabled", isOn: $shortcut.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Delete shortcut")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Trigger")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("e.g. ;email", text: $shortcut.trigger)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .padding(6)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Replacement")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $shortcut.replacement)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(4)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .frame(minHeight: 120, maxHeight: .infinity)
            }
        }
        .padding(12)
    }
}
