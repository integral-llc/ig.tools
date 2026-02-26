import SwiftUI

struct LayoutSwitcherView: View {
    @Bindable var state: LayoutSwitcherState

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            switchLog
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Toggle("", isOn: $state.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()

            Text("EN / RU")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            accessibilityIndicator

            if !state.recentSwitches.isEmpty {
                Button {
                    state.recentSwitches.removeAll()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear history")
            }
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

    // MARK: - Switch log

    private var switchLog: some View {
        Group {
            if state.recentSwitches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No layout switches yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("Type a word on the wrong layout\nand it will be auto-corrected")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(state.recentSwitches) { event in
                        SwitchEventRow(event: event)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

// MARK: - Switch event row

private struct SwitchEventRow: View {
    let event: SwitchEvent

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(event.original)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .strikethrough()
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(event.replacement)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 4) {
                    Text(event.fromLayout)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 7))
                        .foregroundStyle(.tertiary)
                    Text(event.toLayout)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    Spacer()

                    Text(event.date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
