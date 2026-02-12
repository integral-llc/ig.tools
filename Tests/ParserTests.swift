import Testing
@testable import IGTools

@Suite("Parser Tests")
struct ParserTests {

    private func parse(_ input: String) throws -> any ExpressionNode {
        var lexer = Lexer(input)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        return try parser.parse()
    }

    @Test("Parses simple addition")
    func simpleAdd() throws {
        let node = try parse("3 + 4")
        let result = try node.evaluate(context: EvalContext())
        #expect(result == 7)
    }

    @Test("Parses operator precedence: * before +")
    func precedence() throws {
        let node = try parse("2 + 3 * 4")
        let result = try node.evaluate(context: EvalContext())
        #expect(result == 14)
    }

    @Test("Parses parentheses")
    func parentheses() throws {
        let node = try parse("(2 + 3) * 4")
        let result = try node.evaluate(context: EvalContext())
        #expect(result == 20)
    }

    @Test("Parses unary minus")
    func unaryMinus() throws {
        let node = try parse("-5 + 3")
        let result = try node.evaluate(context: EvalContext())
        #expect(result == -2)
    }

    @Test("Parses percentage node in additive context")
    func percentageInAddition() throws {
        // 5 + 30% should create PercentageNode with base
        let node = try parse("5 + 30%")
        let result = try node.evaluate(context: EvalContext())
        #expect(result == 6.5)
    }

    @Test("Parses standalone percentage")
    func standalonePercentage() throws {
        let node = try parse("30%")
        let result = try node.evaluate(context: EvalContext())
        #expect(result == 0.3)
    }

    @Test("Parses power (right-associative)")
    func power() throws {
        let node = try parse("2 ^ 3")
        let result = try node.evaluate(context: EvalContext())
        #expect(result == 8)
    }

    @Test("Parses factorial")
    func factorial() throws {
        let node = try parse("5!")
        let result = try node.evaluate(context: EvalContext())
        #expect(result == 120)
    }

    @Test("Parses function call")
    func functionCall() throws {
        let node = try parse("sqrt(16)")
        let result = try node.evaluate(context: EvalContext())
        #expect(result == 4)
    }

    @Test("Parses assignment")
    func assignment() throws {
        let ctx = EvalContext()
        let node = try parse("$x = 42")
        let result = try node.evaluate(context: ctx)
        #expect(result == 42)
        #expect(ctx.variables["x"] == 42)
    }
}
