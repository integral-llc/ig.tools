import Testing
@testable import IGTools

@Suite("Lexer Tests")
struct LexerTests {

    @Test("Tokenizes numbers and operators")
    func basicTokens() throws {
        var lexer = Lexer("3 + 4.5")
        let tokens = try lexer.tokenize()
        #expect(tokens == [.number(3), .plus, .number(4.5), .eof])
    }

    @Test("Tokenizes variables")
    func variables() throws {
        var lexer = Lexer("$tax * 100")
        let tokens = try lexer.tokenize()
        #expect(tokens == [.variable("tax"), .star, .number(100), .eof])
    }

    @Test("Tokenizes functions")
    func functions() throws {
        var lexer = Lexer("sin(pi)")
        let tokens = try lexer.tokenize()
        #expect(tokens == [.function("sin"), .leftParen, .constant("pi"), .rightParen, .eof])
    }

    @Test("Tokenizes percentage and factorial")
    func percentAndFactorial() throws {
        var lexer = Lexer("5+30%")
        let tokens = try lexer.tokenize()
        #expect(tokens == [.number(5), .plus, .number(30), .percent, .eof])

        var lexer2 = Lexer("5!")
        let tokens2 = try lexer2.tokenize()
        #expect(tokens2 == [.number(5), .bang, .eof])
    }

    @Test("Tokenizes assignment")
    func assignment() throws {
        var lexer = Lexer("$x = 42")
        let tokens = try lexer.tokenize()
        #expect(tokens == [.variable("x"), .equals, .number(42), .eof])
    }

    @Test("Tokenizes complex expression")
    func complex() throws {
        var lexer = Lexer("sqrt(2^2 + 3^2)")
        let tokens = try lexer.tokenize()
        #expect(tokens == [
            .function("sqrt"), .leftParen,
            .number(2), .caret, .number(2),
            .plus,
            .number(3), .caret, .number(2),
            .rightParen, .eof
        ])
    }
}
