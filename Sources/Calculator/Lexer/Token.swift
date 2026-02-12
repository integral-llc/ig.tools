/// Tokens produced by the lexer for the expression parser.
enum Token: Equatable, Sendable {
    case number(Double)
    case variable(String)       // $name
    case function(String)       // sin, cos, etc.
    case constant(String)       // pi, e
    case plus
    case minus
    case star
    case slash
    case caret                  // ^
    case percent                // %
    case bang                   // ! (factorial)
    case leftParen
    case rightParen
    case comma
    case equals                 // = (assignment: $x = 5)
    case eof
}
