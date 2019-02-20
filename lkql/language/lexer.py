from langkit.lexer import Lexer, LexerToken, Literal, WithText, WithSymbol, Pattern, Literal,\
                          Ignore


class Token(LexerToken):
    Identifier = WithSymbol()
    String = WithText()
    TrueLit = WithSymbol()
    FalseLit = WithSymbol()
    Integer = WithText()
    Number = WithText()

    Print = WithSymbol()

    Dot = WithText()
    Eq = WithText()
    EqEq = WithText()
    And = WithText()
    Or = WithText()
    Plus = WithText()
    Minus = WithText()
    Mul = WithText()
    Div = WithText()
    LPar = WithText()
    RPar = WithText()


lkql_lexer = Lexer(Token)
lkql_lexer.add_rules(
    (Pattern(r"[ \t\n\r]"),                                 Ignore()),
    (Literal("."),                                          Token.Dot),
    (Literal("="),                                          Token.Eq),
    (Literal("=="),                                         Token.EqEq),
    (Literal("&&"),                                         Token.And),
    (Literal("||"),                                         Token.Or),
    (Literal("+"),                                          Token.Plus),
    (Literal("-"),                                          Token.Minus),
    (Literal("*"),                                          Token.Mul),
    (Literal("/"),                                          Token.Div),
    (Literal("("),                                          Token.LPar),
    (Literal(")"),                                          Token.RPar),
    (Literal("print"),                                      Token.Print),
    (Literal("true"),                                       Token.TrueLit),
    (Literal("false"),                                      Token.FalseLit),
    (Pattern("[0-9]+"),                                     Token.Integer),
    (Pattern("([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+)"),          Token.Number),
    (Pattern("[a-z][A-Za-z0-9]*"),                          Token.Identifier),
    (Pattern("\"[^\"]*\""),                                 Token.String)
)
