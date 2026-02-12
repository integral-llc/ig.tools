/// Interpreter pattern: AST node that can be evaluated to produce a Double.
protocol ExpressionNode: Sendable {
    func evaluate(context: EvalContext) throws -> Double
}
