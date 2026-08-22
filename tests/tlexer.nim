import std/unittest

import ../src/token
import ../src/lexer

suite "Lexer.nextToken":

    test "tokenizes single-character operators and delimiters":
        let input = "=+(){},;"

        let want: seq[tuple[kind: TokenType, literal: string]] = @[
            (Assign, "="),
            (Plus, "+"),
            (LParen, "("),
            (RParen, ")"),
            (LBrace, "{"),
            (RBrace, "}"),
            (Comma, ","),
            (SemiColon, ";"),
            (EOF, ""),
        ]

        var l = newLexer(input)

        for i, expected in want:
            let got = l.nextToken()
            checkpoint("token[" & $i & "]")
            check got.kind == expected.kind
            check got.literal == expected.literal

    test "returns EOF forever once the input is exhausted":
        var l = newLexer("")

        for i in 0 ..< 3:
            let got = l.nextToken()
            checkpoint("call #" & $i)
            check got.kind == EOF

            check got.literal == ""

    test "tokenizes bindings, a function literal, a call and operators":
        let input = """
let five = 5;
let ten = 10;
let add = fn(x, y){
   x + y;
};
let result = add (five, ten);
!-/*5;
5 < 10 > 5;
10 == 10;
10 != 9;
"""

        let want: seq[tuple[kind: TokenType, literal: string]] = @[
            (Let, "let"), (Ident, "five"), (Assign, "="), (Int, "5"), (
                    SemiColon, ";"),
            (Let, "let"), (Ident, "ten"), (Assign, "="), (Int, "10"), (
                    SemiColon, ";"),
            (Let, "let"), (Ident, "add"), (Assign, "="), (Function, "fn"),
            (LParen, "("), (Ident, "x"), (Comma, ","), (Ident, "y"), (RParen,
                    ")"),
            (LBrace, "{"),
            (Ident, "x"), (Plus, "+"), (Ident, "y"), (SemiColon, ";"),
            (RBrace, "}"), (SemiColon, ";"),
            (Let, "let"), (Ident, "result"), (Assign, "="), (Ident, "add"),
            (LParen, "("), (Ident, "five"), (Comma, ","), (Ident, "ten"), (
                    RParen, ")"),
            (SemiColon, ";"),
            (Bang, "!"), (Minus, "-"), (Slash, "/"), (Asterisk, "*"),
            (Int, "5"), (SemiColon, ";"),
            (Int, "5"), (Lt, "<"), (Int, "10"), (Gt, ">"), (Int, "5"),
            (SemiColon, ";"),
            (Int, "10"), (Eq, "=="), (Int, "10"), (SemiColon, ";"),
            (Int, "10"), (NotEq, "!="), (Int, "9"), (SemiColon, ";"),
            (EOF, ""),
        ]

        var l = newLexer(input)

        for i, expected in want:
            let got = l.nextToken()
            checkpoint("token[" & $i & "] want " & $expected.kind & " \"" &
                    expected.literal & "\"")
            check got.kind == expected.kind
            check got.literal == expected.literal

    test "tokenizes an if/else expression with booleans and return":
        let input = """
if (5 < 10) {
  return true;
} else {
  return false;
}
"""

        let want: seq[tuple[kind: TokenType, literal: string]] = @[
            (If, "if"), (LParen, "("), (Int, "5"), (Lt, "<"), (Int, "10"),
            (RParen, ")"),
            (LBrace, "{"), (Return, "return"), (True, "true"), (SemiColon, ";"),
            (RBrace, "}"),
            (Else, "else"),
            (LBrace, "{"), (Return, "return"), (False, "false"), (SemiColon,
                    ";"),
            (RBrace, "}"),
            (EOF, ""),
        ]

        var l = newLexer(input)

        for i, expected in want:
            let got = l.nextToken()
            checkpoint("token[" & $i & "] want " & $expected.kind & " \"" &
                    expected.literal & "\"")
            check got.kind == expected.kind
            check got.literal == expected.literal
