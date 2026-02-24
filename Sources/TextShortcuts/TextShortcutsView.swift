import SwiftUI

struct TextShortcutsView: View {
    @Bindable var state: TextShortcutsState

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            shortcutList
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Toggle("Enabled", isOn: $state.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)

            Spacer()

            accessibilityIndicator

            Button {
                state.addShortcut()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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

    // MARK: - Shortcut list

    private var shortcutList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if state.shortcuts.isEmpty {
                    Text("No shortcuts defined.\nClick + to add one.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach($state.shortcuts) { $shortcut in
                        ShortcutCardView(shortcut: $shortcut) {
                            state.removeShortcut(shortcut)
                        }
                        Divider()
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Shortcut card

private struct ShortcutCardView: View {
    @Binding var shortcut: TextShortcut
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Trigger")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $shortcut.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            TextField("e.g. ;email", text: $shortcut.trigger)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))

            Text("Replacement")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            TextEditor(text: $shortcut.replacement)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 40, maxHeight: 80)
                .scrollContentBackground(.hidden)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .opacity(shortcut.isEnabled ? 1.0 : 0.5)
    }
}
