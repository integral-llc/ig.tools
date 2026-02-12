import SwiftUI

struct CalculatorView: View {
    @Bindable var state: CalculatorState
    @State private var controller = InputFieldController()

    var body: some View {
        VStack(spacing: 0) {
            inputBar
            if !controller.suggestions.isEmpty {
                suggestionsView
            }
            Divider()
            historyList
            Divider()
            bottomBar
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            HighlightedTextField(
                text: $state.input,
                variables: state.variableNames,
                controller: controller,
                onSubmit: { state.submit() },
                onChange: { state.evaluateInput() }
            )

            if let result = state.liveResult {
                Button {
                    if state.isValid {
                        state.copyResult(result)
                    }
                } label: {
                    Text("= \(result)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(state.isValid ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .help(state.isValid ? "Click to copy" : "Invalid expression")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(controller.suggestions.enumerated()), id: \.element) { index, name in
                let isSelected = index == controller.selectedIndex
                Button {
                    controller.complete(with: name)
                } label: {
                    HStack {
                        Text("$\(name)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.green)
                        Spacer()
                        Text(state.formattedVariableValue(name))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .contentShape(Rectangle())
                    .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - History

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(state.history) { entry in
                    HistoryRowView(entry: entry, isCopied: state.copiedEntryID == entry.id) {
                        state.copyResult(entry.formattedResult, entryID: entry.id)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack {
            Button("Variables") {
                VariablesWindowController.shared.show(state: state)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            memoryControls

            Spacer()

            Text("M: \(state.formattedMemory)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var memoryControls: some View {
        HStack(spacing: 6) {
            memoryButton("MC", action: state.memoryClear)
            memoryButton("MR", action: state.memoryRecall)
            memoryButton("M+", action: state.memoryAdd)
            memoryButton("M−", action: state.memorySub)
            memoryButton("MS", action: state.memoryStore)
        }
    }

    private func memoryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.plain)
            .font(.system(.caption2, design: .monospaced, weight: .medium))
            .foregroundStyle(.secondary)
    }
}

// MARK: - History Row

struct HistoryRowView: View {
    let entry: HistoryEntry
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        Button(action: onCopy) {
            HStack {
                Text(entry.expression)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Text(isCopied ? "Copied!" : "= \(entry.formattedResult)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(isCopied ? .green : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
