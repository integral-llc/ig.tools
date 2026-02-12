import Testing
@testable import IGTools

@Suite("Calculator Integration Tests")
struct CalculatorIntegrationTests {

    /// End-to-end: string in → result out via Evaluator
    private func eval(_ input: String, vars: [String: Double] = [:]) throws -> Double {
        try Evaluator.evaluate(input, context: EvalContext(variables: vars))
    }

    @Test("Full pipeline: 5 + 30% = 6.5")
    func percentagePipeline() throws {
        #expect(try eval("5 + 30%") == 6.5)
    }

    @Test("Full pipeline: sin(pi/2) = 1")
    func sinPipeline() throws {
        let result = try eval("sin(pi/2)")
        #expect(abs(result - 1) < 1e-10)
    }

    @Test("Full pipeline: variable usage")
    func variablePipeline() throws {
        #expect(try eval("$tax * 100", vars: ["tax": 8.5]) == 850)
    }

    @Test("Full pipeline: chained operations")
    func chainedOps() throws {
        #expect(try eval("2 ^ 3 + 5! - sqrt(16)") == 128 - 4)
    }

    @Test("Full pipeline: nested parentheses")
    func nestedParens() throws {
        #expect(try eval("((2 + 3) * (4 - 1)) / 5") == 3)
    }

    @Test("Empty input throws")
    func emptyInput() throws {
        #expect(throws: ExpressionError.self) { try eval("") }
    }

    @Test("Whitespace-only throws")
    func whitespaceOnly() throws {
        #expect(throws: ExpressionError.self) { try eval("   ") }
    }

    @Test("Number formatting: integer")
    func formatInteger() {
        #expect(NumberFormatterExt.format(42) == "42")
    }

    @Test("Number formatting: decimal")
    func formatDecimal() {
        #expect(NumberFormatterExt.format(6.5) == "6.5")
    }

    @Test("Number formatting: infinity")
    func formatInfinity() {
        #expect(NumberFormatterExt.format(Double.infinity) == "∞")
    }
}
