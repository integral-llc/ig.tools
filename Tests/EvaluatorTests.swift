import Testing
import Foundation
@testable import IGTools

@Suite("Evaluator Tests")
struct EvaluatorTests {

    private func eval(_ input: String, context: EvalContext? = nil) throws -> Double {
        try Evaluator.evaluate(input, context: context ?? EvalContext())
    }

    // MARK: - Basic arithmetic

    @Test("Basic addition")
    func add() throws { #expect(try eval("3 + 4") == 7) }

    @Test("Basic subtraction")
    func sub() throws { #expect(try eval("10 - 3") == 7) }

    @Test("Multiplication")
    func mul() throws { #expect(try eval("3 * 4") == 12) }

    @Test("Division")
    func div() throws { #expect(try eval("10 / 4") == 2.5) }

    @Test("Division by zero throws")
    func divByZero() throws {
        #expect(throws: ExpressionError.self) { try eval("1 / 0") }
    }

    // MARK: - Precedence

    @Test("Operator precedence")
    func precedence() throws { #expect(try eval("2 + 3 * 4") == 14) }

    @Test("Parentheses override precedence")
    func parens() throws { #expect(try eval("(2 + 3) * 4") == 20) }

    // MARK: - Percentage

    @Test("Percentage of base: 5 + 30% = 6.5")
    func percentOfBase() throws { #expect(try eval("5 + 30%") == 6.5) }

    @Test("Percentage subtraction: 200 - 10% = 180")
    func percentSubtract() throws { #expect(try eval("200 - 10%") == 180) }

    @Test("Standalone percentage: 50% = 0.5")
    func standalonePercent() throws { #expect(try eval("50%") == 0.5) }

    @Test("Chained percentage: 100 + 10% + 20% = 132")
    func chainedPercent() throws { #expect(try eval("100 + 10% + 20%") == 132) }

    // MARK: - Power & Factorial

    @Test("Power")
    func power() throws { #expect(try eval("2 ^ 10") == 1024) }

    @Test("Factorial")
    func factorial() throws { #expect(try eval("5!") == 120) }

    @Test("Factorial of 0")
    func factorialZero() throws { #expect(try eval("0!") == 1) }

    // MARK: - Unary

    @Test("Unary minus")
    func unaryMinus() throws { #expect(try eval("-5 + 3") == -2) }

    @Test("Double negative")
    func doubleNeg() throws { #expect(try eval("--5") == 5) }

    // MARK: - Functions

    @Test("sin(0) = 0")
    func sinZero() throws { #expect(try eval("sin(0)") == 0) }

    @Test("cos(0) = 1")
    func cosZero() throws { #expect(try eval("cos(0)") == 1) }

    @Test("sqrt(144) = 12")
    func sqrtTest() throws { #expect(try eval("sqrt(144)") == 12) }

    @Test("log(100) = 2")
    func logTest() throws { #expect(try eval("log(100)") == 2) }

    @Test("abs(-42) = 42")
    func absTest() throws { #expect(try eval("abs(-42)") == 42) }

    @Test("min(3, 1, 2) = 1")
    func minTest() throws { #expect(try eval("min(3, 1, 2)") == 1) }

    @Test("max(3, 1, 2) = 3")
    func maxTest() throws { #expect(try eval("max(3, 1, 2)") == 3) }

    @Test("pow(2, 8) = 256")
    func powTest() throws { #expect(try eval("pow(2, 8)") == 256) }

    @Test("round(3.7) = 4")
    func roundTest() throws { #expect(try eval("round(3.7)") == 4) }

    @Test("ceil(3.2) = 4")
    func ceilTest() throws { #expect(try eval("ceil(3.2)") == 4) }

    @Test("floor(3.8) = 3")
    func floorTest() throws { #expect(try eval("floor(3.8)") == 3) }

    // MARK: - Constants

    @Test("pi ≈ 3.14159")
    func piConstant() throws {
        let result = try eval("pi")
        #expect(abs(result - Double.pi) < 1e-10)
    }

    @Test("e ≈ 2.71828")
    func eConstant() throws {
        let result = try eval("e")
        #expect(abs(result - M_E) < 1e-10)
    }

    @Test("sin(pi/2) = 1")
    func sinPiHalf() throws {
        let result = try eval("sin(pi / 2)")
        #expect(abs(result - 1) < 1e-10)
    }

    // MARK: - Variables

    @Test("Variable usage")
    func variables() throws {
        let ctx = EvalContext(variables: ["tax": .number(8.5)])
        #expect(try eval("$tax * 100", context: ctx) == 850)
    }

    @Test("Variable assignment and use")
    func assignment() throws {
        let ctx = EvalContext()
        _ = try eval("$x = 10", context: ctx)
        #expect(try eval("$x * 5", context: ctx) == 50)
    }

    @Test("Undefined variable throws")
    func undefinedVar() throws {
        #expect(throws: ExpressionError.self) { try eval("$nope + 1") }
    }

    // MARK: - Complex expressions

    @Test("Nested functions: sqrt(sin(pi/2)^2 + cos(pi/2)^2) ≈ 1")
    func pythagoreanIdentity() throws {
        let result = try eval("sqrt(sin(pi/2)^2 + cos(pi/2)^2)")
        #expect(abs(result - 1) < 1e-10)
    }

    @Test("Complex: (3 + 4) * 2 - 1 = 13")
    func complex1() throws { #expect(try eval("(3 + 4) * 2 - 1") == 13) }

    @Test("ln(e) = 1")
    func lnE() throws {
        let result = try eval("ln(e)")
        #expect(abs(result - 1) < 1e-10)
    }
}
