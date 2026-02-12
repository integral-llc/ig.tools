import SwiftUI

struct VariablesView: View {
    @Bindable var state: CalculatorState
    @State private var newName: String = ""
    @State private var newValue: String = ""
    @State private var editingName: String? = nil
    @State private var editText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            variableList
            Divider()
            addRow
        }
        .frame(width: 320, height: 300)
    }

    private var header: some View {
        HStack {
            Text("Variables")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var variableList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if state.sortedVariables.isEmpty {
                    Text("No variables defined")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 20)
                } else {
                    ForEach(state.sortedVariables, id: \.name) { variable in
                        variableRow(variable)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func variableRow(_ variable: (name: String, value: Double)) -> some View {
        HStack {
            Text("$\(variable.name)")
                .font(.system(.body, design: .monospaced))

            Spacer()

            if editingName == variable.name {
                TextField("value", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
                    .onSubmit { commitEdit(variable.name) }
                    .onExitCommand { editingName = nil }
            } else {
                Text(NumberFormatterExt.format(variable.value))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        editingName = variable.name
                        editText = NumberFormatterExt.format(variable.value)
                    }
            }

            Button {
                state.removeVariable(variable.name)
                if editingName == variable.name { editingName = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func commitEdit(_ name: String) {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        if let value = evaluateExpression(trimmed) {
            state.setVariable(name, value)
        }
        editingName = nil
    }

    private var addRow: some View {
        HStack(spacing: 8) {
            Text("$")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            TextField("name", text: $newName)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .frame(width: 80)
            Text("=")
                .foregroundStyle(.secondary)
            TextField("value or expr", text: $newValue)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .frame(width: 100)
                .onSubmit(addVariable)
            Button("Add", action: addVariable)
                .buttonStyle(.plain)
                .font(.caption)
                .disabled(!canAdd)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var canAdd: Bool {
        let name = newName.trimmingCharacters(in: .whitespaces)
        let value = newValue.trimmingCharacters(in: .whitespaces)
        return !name.isEmpty && !value.isEmpty && evaluateExpression(value) != nil
    }

    private func addVariable() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        let valueStr = newValue.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let value = evaluateExpression(valueStr) else { return }
        state.setVariable(name, value)
        newName = ""
        newValue = ""
    }

    /// Evaluate an expression string using the calculator's evaluator.
    /// Supports numbers, percentages, math expressions, etc.
    private func evaluateExpression(_ input: String) -> Double? {
        guard !input.isEmpty else { return nil }
        let ctx = state.context.copy()
        return try? Evaluator.evaluate(input, context: ctx)
    }
}
