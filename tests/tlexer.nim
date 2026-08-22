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
