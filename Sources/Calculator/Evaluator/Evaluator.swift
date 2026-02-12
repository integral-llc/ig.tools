import Foundation

/// Expression error types.
enum ExpressionError: Error, LocalizedError, Sendable {
    case unexpectedCharacter(Character)
    case emptyVariableName
    case unexpectedToken
    case divisionByZero
    case invalidFactorial
    case undefinedVariable(String)
    case undefinedConstant(String)
    case undefinedFunction(String)
    case wrongArgumentCount(String, Int, Int)

    var errorDescription: String? {
        switch self {
        case .unexpectedCharacter(let ch): "Unexpected character: \(ch)"
        case .emptyVariableName:           "Empty variable name after $"
        case .unexpectedToken:             "Unexpected token"
        case .divisionByZero:              "Division by zero"
        case .invalidFactorial:            "Invalid factorial operand"
        case .undefinedVariable(let n):    "Undefined variable: $\(n)"
        case .undefinedConstant(let n):    "Unknown constant: \(n)"
        case .undefinedFunction(let n):    "Unknown function: \(n)"
        case .wrongArgumentCount(let fn, let expected, let got):
            "\(fn) expects \(expected) argument(s), got \(got)"
        }
    }
}

/// Tree-walking evaluator: parses and evaluates an expression string.
enum Evaluator {
    static func evaluate(_ input: String, context: EvalContext) throws -> Double {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw ExpressionError.unexpectedToken }

        var lexer = Lexer(trimmed)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        return try ast.evaluate(context: context)
    }
}
