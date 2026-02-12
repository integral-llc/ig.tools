import Testing
@testable import IGTools

@Suite("Percentage Variable Tests")
struct PercentageVariableTests {

    @Test("Percentage variable assignment and usage")
    func percentageVariables() throws {
        let ctx = EvalContext()

        // Test percentage assignment
        _ = try Evaluator.evaluate("$x = 30%", context: ctx)
        #expect(ctx.variables["x"]?.isPercentage == true)
        #expect(ctx.variables["x"]?.percentageValue == 30) // Use percentageValue, not value

        // Test percentage variable in addition
        #expect(try Evaluator.evaluate("$x + 50", context: ctx) == 65) // 30% of 50 + 50 = 15 + 50 = 65

        // Test percentage variable in subtraction
        #expect(try Evaluator.evaluate("$x - 50", context: ctx) == 35) // 50 - 30% of 50 = 50 - 15 = 35

        // Test percentage variable with multiplication (should treat as number)
        #expect(try Evaluator.evaluate("$x * 50", context: ctx) == 15) // 0.3 * 50 = 15

        // Test percentage variable with division (should treat as number)
        #expect(try Evaluator.evaluate("$x / 50", context: ctx) == 0.006) // 0.3 / 50 = 0.006
    }

    @Test("Regular variable still works")
    func regularVariables() throws {
        let ctx = EvalContext()

        // Test regular number assignment
        _ = try Evaluator.evaluate("$y = 30", context: ctx)
        #expect(ctx.variables["y"]?.isPercentage == false)
        #expect(ctx.variables["y"]?.value == 30)

        // Test regular variable in addition
        #expect(try Evaluator.evaluate("$y + 50", context: ctx) == 80) // 30 + 50 = 80
    }

    @Test("Mixed percentage and regular variables")
    func mixedVariables() throws {
        let ctx = EvalContext()

        // Set up both types of variables
        _ = try Evaluator.evaluate("$x = 30%", context: ctx)
        _ = try Evaluator.evaluate("$y = 30", context: ctx)

        // Test percentage variable
        #expect(try Evaluator.evaluate("$x + 50", context: ctx) == 65) // 30% of 50 + 50 = 65

        // Test regular variable
        #expect(try Evaluator.evaluate("$y + 50", context: ctx) == 80) // 30 + 50 = 80
    }

    @Test("Percentage variable as right operand")
    func percentageVariableRight() throws {
        let ctx = EvalContext()

        _ = try Evaluator.evaluate("$x = 20%", context: ctx)

        // Test percentage variable on the right side
        #expect(try Evaluator.evaluate("100 + $x", context: ctx) == 120) // 100 + 20% of 100 = 120
        #expect(try Evaluator.evaluate("100 - $x", context: ctx) == 80) // 100 - 20% of 100 = 80
    }

    @Test("Chained operations with percentage variables")
    func chainedOperations() throws {
        let ctx = EvalContext()

        _ = try Evaluator.evaluate("$x = 10%", context: ctx)

        // Test chained operations (note: percentages compound in chained operations)
        #expect(try Evaluator.evaluate("$x + 100 + $x", context: ctx) == 121) // (100 + 10% of 100) + 10% of result = 110 + 11 = 121
    }
}
