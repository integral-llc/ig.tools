import Foundation

/// Holds variables, memory register, and constants for expression evaluation.
final class EvalContext: Sendable {
    // Using a lock-free approach: these are only accessed from @MainActor in practice
    nonisolated(unsafe) var variables: [String: VariableValue]
    nonisolated(unsafe) var memory: Double
    nonisolated(unsafe) var lastResultIsPercentage: Bool = false

    init(variables: [String: VariableValue] = [:], memory: Double = 0) {
        self.variables = variables
        self.memory = memory
    }

    func copy() -> EvalContext {
        EvalContext(variables: variables, memory: memory)
    }
}
