import Foundation

// MARK: - Concrete AST Nodes (Interpreter pattern)

struct NumberNode: ExpressionNode {
    let value: Double
    func evaluate(context: EvalContext) throws -> Double { value }
}

struct BinaryOpNode: ExpressionNode {
    enum Op: Sendable { case add, subtract, multiply, divide, power }
    let op: Op
    let left: any ExpressionNode
    let right: any ExpressionNode

    func evaluate(context: EvalContext) throws -> Double {
        let l = try left.evaluate(context: context)
        let r = try right.evaluate(context: context)
        switch op {
        case .add:      return l + r
        case .subtract: return l - r
        case .multiply: return l * r
        case .divide:
            guard r != 0 else { throw ExpressionError.divisionByZero }
            return l / r
        case .power:    return pow(l, r)
        }
    }
}

struct UnaryMinusNode: ExpressionNode {
    let operand: any ExpressionNode
    func evaluate(context: EvalContext) throws -> Double {
        -(try operand.evaluate(context: context))
    }
}

struct FactorialNode: ExpressionNode {
    let operand: any ExpressionNode
    func evaluate(context: EvalContext) throws -> Double {
        let val = try operand.evaluate(context: context)
        guard val >= 0, val == val.rounded(), val <= 170 else {
            throw ExpressionError.invalidFactorial
        }
        return factorial(Int(val))
    }

    private func factorial(_ n: Int) -> Double {
        n <= 1 ? 1 : Double(n) * factorial(n - 1)
    }
}

/// Percentage-of-base node: in `a + b%`, base=a, percentage=b → a * b/100
struct PercentageNode: ExpressionNode {
    let base: (any ExpressionNode)?
    let percentage: any ExpressionNode

    func evaluate(context: EvalContext) throws -> Double {
        let pct = try percentage.evaluate(context: context)
        if let base {
            let b = try base.evaluate(context: context)
            return b * pct / 100.0
        }
        // Standalone: 30% → 0.3
        return pct / 100.0
    }
}

struct VariableNode: ExpressionNode {
    let name: String
    func evaluate(context: EvalContext) throws -> Double {
        guard let value = context.variables[name] else {
            throw ExpressionError.undefinedVariable(name)
        }
        return value
    }
}

struct ConstantNode: ExpressionNode {
    let name: String
    func evaluate(context: EvalContext) throws -> Double {
        switch name {
        case "pi": return Double.pi
        case "e":  return M_E
        default:   throw ExpressionError.undefinedConstant(name)
        }
    }
}

struct FunctionCallNode: ExpressionNode {
    let name: String
    let arguments: [any ExpressionNode]

    func evaluate(context: EvalContext) throws -> Double {
        let args = try arguments.map { try $0.evaluate(context: context) }
        guard let fn = Functions.lookup(name) else {
            throw ExpressionError.undefinedFunction(name)
        }
        return try fn(args)
    }
}

struct AssignmentNode: ExpressionNode {
    let variableName: String
    let value: any ExpressionNode

    func evaluate(context: EvalContext) throws -> Double {
        let result = try value.evaluate(context: context)
        context.variables[variableName] = result
        return result
    }
}
