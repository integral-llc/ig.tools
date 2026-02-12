import Foundation

/// Registry of built-in scientific functions.
enum Functions {
    typealias MathFn = @Sendable ([Double]) throws -> Double

    static let allNames: [String] = Array(registry.keys)

    static func lookup(_ name: String) -> MathFn? {
        registry[name]
    }

    private static let registry: [String: MathFn] = [
        // Trigonometric
        "sin":   { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("sin", 1, args.count) }; return sin(args[0]) },
        "cos":   { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("cos", 1, args.count) }; return cos(args[0]) },
        "tan":   { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("tan", 1, args.count) }; return tan(args[0]) },
        "asin":  { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("asin", 1, args.count) }; return asin(args[0]) },
        "acos":  { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("acos", 1, args.count) }; return acos(args[0]) },
        "atan":  { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("atan", 1, args.count) }; return atan(args[0]) },

        // Logarithmic / Exponential
        "log":   { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("log", 1, args.count) }; return log10(args[0]) },
        "ln":    { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("ln", 1, args.count) }; return log(args[0]) },
        "exp":   { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("exp", 1, args.count) }; return exp(args[0]) },

        // Common
        "sqrt":  { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("sqrt", 1, args.count) }; return sqrt(args[0]) },
        "abs":   { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("abs", 1, args.count) }; return abs(args[0]) },
        "round": { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("round", 1, args.count) }; return (args[0]).rounded() },
        "ceil":  { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("ceil", 1, args.count) }; return ceil(args[0]) },
        "floor": { args in guard args.count == 1 else { throw ExpressionError.wrongArgumentCount("floor", 1, args.count) }; return floor(args[0]) },

        // Multi-arg
        "min":   { args in guard args.count >= 2 else { throw ExpressionError.wrongArgumentCount("min", 2, args.count) }; return args.min()! },
        "max":   { args in guard args.count >= 2 else { throw ExpressionError.wrongArgumentCount("max", 2, args.count) }; return args.max()! },
        "pow":   { args in guard args.count == 2 else { throw ExpressionError.wrongArgumentCount("pow", 2, args.count) }; return pow(args[0], args[1]) },
    ]
}
