from langkit.lexer import Lexer, LexerToken, Literal, WithText, WithSymbol, Pattern, Literal,\
                          Ignore


class Token(LexerToken):
    Identifier = WithSymbol()
    String = WithText()
    Integer = WithText()

    Let = WithSymbol()
    Query = WithSymbol()
    When = WithSymbol()
    Is = WithSymbol()
    In = WithSymbol()
    Print = WithSymbol()
    TrueLit = WithSymbol()
    FalseLit = WithSymbol()

    Dot = WithText()
    Eq = WithText()
    EqEq = WithText()
    Neq = WithText()
    And = WithText()
    Or = WithText()
    Plus = WithText()
    Minus = WithText()
    Mul = WithText()
    Div = WithText()
    LPar = WithText()
    RPar = WithText()
    LBrack = WithText()
    RBrack = WithText()


lkql_lexer = Lexer(Token)
lkql_lexer.add_rules(
    (Pattern(r"[ \t\n\r]"),                                 Ignore()),
    (Literal("."),                                          Token.Dot),
    (Literal("="),                                          Token.Eq),
    (Literal("=="),                                         Token.EqEq),
    (Literal("!="),                                         Token.Neq),
    (Literal("&&"),                                         Token.And),
    (Literal("||"),                                         Token.Or),
    (Literal("+"),                                          Token.Plus),
    (Literal("-"),                                          Token.Minus),
    (Literal("*"),                                          Token.Mul),
    (Literal("/"),                                          Token.Div),
    (Literal("("),                                          Token.LPar),
    (Literal(")"),                                          Token.RPar),
    (Literal("["),                                          Token.LBrack),
    (Literal("]"),                                          Token.RBrack),
    (Literal("let"),                                        Token.Let),
    (Literal("query"),                                      Token.Query),
    (Literal("when"),                                       Token.When),
    (Literal("is"),                                         Token.Is),
    (Literal("in"),                                         Token.In),
    (Literal("print"),                                      Token.Print),
    (Literal("true"),                                       Token.TrueLit),
    (Literal("false"),                                      Token.FalseLit),
    (Pattern("[0-9]+"),                                     Token.Integer),
    (Pattern("[A-Za-z][A-Za-z0-9_]*"),                      Token.Identifier),
    (Pattern("\"[^\"]*\""),                                 Token.String)
)
