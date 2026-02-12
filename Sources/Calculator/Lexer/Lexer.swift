/// Tokenizes an expression string into a sequence of Tokens.
struct Lexer: Sendable {
    private let source: String
    private var index: String.Index
    private let knownFunctions: Set<String>
    private let knownConstants: Set<String>

    init(_ source: String) {
        self.source = source
        self.index = source.startIndex
        self.knownFunctions = Set(Functions.allNames)
        self.knownConstants = ["pi", "e"]
    }

    mutating func tokenize() throws -> [Token] {
        var tokens: [Token] = []
        while let token = try nextToken() {
            tokens.append(token)
        }
        tokens.append(.eof)
        return tokens
    }

    // MARK: - Private

    private var current: Character? {
        index < source.endIndex ? source[index] : nil
    }

    private mutating func advance() {
        index = source.index(after: index)
    }

    private mutating func nextToken() throws -> Token? {
        skipWhitespace()
        guard let ch = current else { return nil }

        switch ch {
        case "+": advance(); return .plus
        case "-": advance(); return .minus
        case "*": advance(); return .star
        case "/": advance(); return .slash
        case "^": advance(); return .caret
        case "%": advance(); return .percent
        case "!": advance(); return .bang
        case "(": advance(); return .leftParen
        case ")": advance(); return .rightParen
        case ",": advance(); return .comma
        case "=": advance(); return .equals
        case "$": return try readVariable()
        default:
            if ch.isNumber || ch == "." {
                return readNumber()
            } else if ch.isLetter {
                return readIdentifier()
            }
            throw ExpressionError.unexpectedCharacter(ch)
        }
    }

    private mutating func skipWhitespace() {
        while let ch = current, ch.isWhitespace {
            advance()
        }
    }

    private mutating func readNumber() -> Token {
        var str = ""
        var hasDot = false
        while let ch = current, ch.isNumber || (ch == "." && !hasDot) {
            if ch == "." { hasDot = true }
            str.append(ch)
            advance()
        }
        return .number(Double(str) ?? 0)
    }

    private mutating func readVariable() throws -> Token {
        advance() // skip $
        var name = ""
        while let ch = current, ch.isLetter || ch.isNumber || ch == "_" {
            name.append(ch)
            advance()
        }
        guard !name.isEmpty else { throw ExpressionError.emptyVariableName }
        return .variable(name)
    }

    private mutating func readIdentifier() -> Token {
        var name = ""
        while let ch = current, ch.isLetter || ch.isNumber || ch == "_" {
            name.append(ch)
            advance()
        }
        let lower = name.lowercased()
        if knownFunctions.contains(lower) {
            return .function(lower)
        } else if knownConstants.contains(lower) {
            return .constant(lower)
        }
        // Treat unknown identifiers as constants (will fail at eval time)
        return .constant(lower)
    }
}
