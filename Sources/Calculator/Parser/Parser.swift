/// Recursive descent parser producing an AST from tokens.
///
/// Grammar:
///   expression     := assignment | additive
///   assignment     := VARIABLE '=' expression
///   additive       := multiplicative ( ('+' | '-') percentage_or_mult )*
///   percentage_or_mult := multiplicative '%'?
///   multiplicative := power ( ('*' | '/') unary )*
///   power          := unary ( '^' unary )*
///   unary          := ('-' | '+') unary | postfix
///   postfix        := primary '!'?
///   primary        := NUMBER | VARIABLE | FUNCTION '(' arglist ')' | '(' expression ')' | CONSTANT
struct Parser: Sendable {
    private var tokens: [Token]
    private var position: Int = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    mutating func parse() throws -> any ExpressionNode {
        let node = try parseExpression()
        guard current == .eof else {
            throw ExpressionError.unexpectedToken
        }
        return node
    }

    // MARK: - Token access

    private var current: Token {
        position < tokens.count ? tokens[position] : .eof
    }

    private func peek(offset: Int = 1) -> Token {
        let idx = position + offset
        return idx < tokens.count ? tokens[idx] : .eof
    }

    @discardableResult
    private mutating func advance() -> Token {
        let tok = current
        position += 1
        return tok
    }

    private mutating func expect(_ token: Token) throws {
        guard current == token else {
            throw ExpressionError.unexpectedToken
        }
        advance()
    }

    // MARK: - Grammar rules

    private mutating func parseExpression() throws -> any ExpressionNode {
        // Check for assignment: $var = expr
        if case .variable(let name) = current, peek() == .equals {
            advance() // skip variable
            advance() // skip =
            let value = try parseExpression()
            return AssignmentNode(variableName: name, value: value)
        }
        return try parseAdditive()
    }

    private mutating func parseAdditive() throws -> any ExpressionNode {
        var left = try parseMultiplicative()

        // Standalone percentage: `30%` at top level → 0.3
        if current == .percent {
            advance()
            left = PercentageNode(base: nil, percentage: left)
        }

        while current == .plus || current == .minus {
            let op = advance()
            var right = try parseMultiplicative()

            // Percentage-of-base: `5 + 30%` → 5 + (5 * 30/100) = 6.5
            if current == .percent {
                advance()
                right = PercentageNode(base: left, percentage: right)
            }

            left = BinaryOpNode(
                op: op == .plus ? .add : .subtract,
                left: left,
                right: right
            )
        }
        return left
    }

    private mutating func parseMultiplicative() throws -> any ExpressionNode {
        var left = try parsePower()

        while current == .star || current == .slash {
            let op = advance()
            let right = try parseUnary()
            left = BinaryOpNode(
                op: op == .star ? .multiply : .divide,
                left: left,
                right: right
            )
        }
        return left
    }

    private mutating func parsePower() throws -> any ExpressionNode {
        var base = try parseUnary()

        // Right-associative
        if current == .caret {
            advance()
            let exponent = try parseUnary()
            base = BinaryOpNode(op: .power, left: base, right: exponent)
        }
        return base
    }

    private mutating func parseUnary() throws -> any ExpressionNode {
        if current == .minus {
            advance()
            let operand = try parseUnary()
            return UnaryMinusNode(operand: operand)
        }
        if current == .plus {
            advance()
            return try parseUnary()
        }
        return try parsePostfix()
    }

    private mutating func parsePostfix() throws -> any ExpressionNode {
        var node = try parsePrimary()

        if current == .bang {
            advance()
            node = FactorialNode(operand: node)
        }
        return node
    }

    private mutating func parsePrimary() throws -> any ExpressionNode {
        switch current {
        case .number(let value):
            advance()
            return NumberNode(value: value)

        case .variable(let name):
            advance()
            return VariableNode(name: name)

        case .constant(let name):
            advance()
            return ConstantNode(name: name)

        case .function(let name):
            advance()
            try expect(.leftParen)
            var args: [any ExpressionNode] = []
            if current != .rightParen {
                args.append(try parseExpression())
                while current == .comma {
                    advance()
                    args.append(try parseExpression())
                }
            }
            try expect(.rightParen)
            return FunctionCallNode(name: name, arguments: args)

        case .leftParen:
            advance()
            let node = try parseExpression()
            try expect(.rightParen)
            return node

        default:
            throw ExpressionError.unexpectedToken
        }
    }
}
