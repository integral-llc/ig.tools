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
        let leftVal = try left.evaluate(context: context)
        let rightVal = try right.evaluate(context: context)

        // Check for percentage variables in additive operations
        if op == .add || op == .subtract {
            // Check if left operand is a percentage variable
            if let leftVar = left as? VariableNode,
               case .percentage = context.variables[leftVar.name] {
                // Apply percentage to right operand
                let base = rightVal
                let percentageValue = base * leftVal // leftVal is already the decimal percentage
                return try applyOperation(base, percentageValue, op)
            }

            // Check if right operand is a percentage variable
            if let rightVar = right as? VariableNode,
               case .percentage = context.variables[rightVar.name] {
                // Apply percentage to left operand
                let base = leftVal
                let percentageValue = base * rightVal // rightVal is already the decimal percentage
                return try applyOperation(base, percentageValue, op)
            }
        }

        // Normal evaluation
        return try applyOperation(leftVal, rightVal, op)
    }

    private func applyOperation(_ left: Double, _ right: Double, _ op: Op) throws -> Double {
        switch op {
        case .add:      return left + right
        case .subtract: return left - right
        case .multiply: return left * right
        case .divide:
            guard right != 0 else { throw ExpressionError.divisionByZero }
            return left / right
        case .power:    return pow(left, right)
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
        context.lastResultIsPercentage = true
        return pct / 100.0
    }
}

struct VariableNode: ExpressionNode {
    let name: String
    func evaluate(context: EvalContext) throws -> Double {
        guard let variableValue = context.variables[name] else {
            throw ExpressionError.undefinedVariable(name)
        }
        return variableValue.value
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

        // Check if the value is a standalone percentage expression
        if let percentageNode = value as? PercentageNode, percentageNode.base == nil {
            context.variables[variableName] = .percentage(result) // Store as decimal (e.g., 0.3 for 30%)
        } else {
            context.variables[variableName] = .number(result)
        }

        return result
    }
}
