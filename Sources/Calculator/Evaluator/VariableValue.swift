import Foundation

/// Represents a variable value with type information.
enum VariableValue: Codable {
    case number(Double)
    case percentage(Double) // Stored as decimal (0.3 for 30%)

    /// The numeric value of the variable.
    var value: Double {
        switch self {
        case .number(let v): return v
        case .percentage(let v): return v
        }
    }

    /// The percentage value (e.g., 30 for 30%).
    var percentageValue: Double {
        switch self {
        case .number(let v): return v
        case .percentage(let v): return v * 100
        }
    }

    /// Whether this variable is a percentage.
    var isPercentage: Bool {
        if case .percentage = self { return true }
        return false
    }
}
