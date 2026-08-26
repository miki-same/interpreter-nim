import std/unittest

import ../src/lexer
import ../src/parser
import ../src/ast
import ../src/token


suite "Program.display":

    test "displays a let statement":
        let program = Program(statements: @[
            Statement(
                kind: StLet,
                name: Expression(
                    kind: ExIdentifier,
                    token: Token(kind: Ident, literal: "myVar"),
                    value: "myVar",
                ),
                value: Expression(
                    kind: ExIdentifier,
                    token: Token(kind: Ident, literal: "anotherVar"),
                    value: "anotherVar",
                ),
            ),
        ])

        check program.display() == "let myVar = anotherVar;"

    test "displays a return statement":
        let program = Program(statements: @[
            Statement(
                kind: StReturn,
                returnValue: Expression(
                    kind: ExIdentifier,
                    token: Token(kind: Ident, literal: "anotherVar"),
                    value: "anotherVar",
                ),
            ),
        ])

        check program.display() == "return anotherVar;"


suite "Parser.parseProgram":

    test "parses let statements":
        let input = """
let x = 5;
let y = 10;
let foobar = 838383;
"""
        let want = @["x", "y", "foobar"]

        var lexer = newLexer(input)
        var parser = newParser(lexer)
        let program = parser.parseProgram().value

        require program.statements.len == want.len

        for i, expectedName in want:
            checkpoint("statement[" & $i & "]")
            check program.statements[i].kind == StLet
            check program.statements[i].name.value == expectedName

    test "parses return statements":
        let input = """
return 5;
return 10;
return 993322;
"""

        var lexer = newLexer(input)
        var parser = newParser(lexer)
        let parsed = parser.parseProgram()

        if parsed.isErr:
            checkpoint("parse error: " & parsed.error)
        require parsed.isOk

        let program = parsed.value
        require program.statements.len == 3

        for i, statement in program.statements:
            checkpoint("statement[" & $i & "]")
            check statement.kind == StReturn
            check statement.tokenLiteral() == "return"
