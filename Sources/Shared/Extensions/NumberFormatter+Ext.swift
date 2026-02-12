import Foundation

/// Smart number formatting: strips trailing zeros, caps decimal places.
enum NumberFormatterExt {
    static func format(_ value: Double) -> String {
        if value.isInfinite { return value > 0 ? "∞" : "-∞" }
        if value.isNaN { return "NaN" }

        // If it's an integer, show without decimals
        if value == value.rounded() && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }

        // Otherwise, up to 10 significant decimal places, strip trailing zeros
        let formatted = String(format: "%.10g", value)
        return formatted
    }
}
