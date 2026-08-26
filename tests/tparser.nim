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
                    idValue: "myVar",
                ),
                value: Expression(
                    kind: ExIdentifier,
                    token: Token(kind: Ident, literal: "anotherVar"),
                    idValue: "anotherVar",
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
                    idValue: "anotherVar",
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
            check program.statements[i].name.idValue == expectedName

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

    test "parses an identifier expression statement":
        let input = "foobar;"

        var lexer = newLexer(input)
        var parser = newParser(lexer)
        let parsed = parser.parseProgram()

        if parsed.isErr:
            checkpoint("parse error: " & parsed.error)
        require parsed.isOk

        let program = parsed.value
        require program.statements.len == 1
        require program.statements[0].kind == StExpression

        let expression = program.statements[0].expression
        check expression.kind == ExIdentifier
        check expression.idValue == "foobar"

    test "parses an integer literal expression statement":
        let input = "5;"

        var lexer = newLexer(input)
        var parser = newParser(lexer)
        let parsed = parser.parseProgram()

        if parsed.isErr:
            checkpoint("parse error: " & parsed.error)
        require parsed.isOk

        let program = parsed.value
        require program.statements.len == 1
        require program.statements[0].kind == StExpression

        let expression = program.statements[0].expression
        check expression.kind == ExIntegerLiteral
        check expression.intValue == 5
