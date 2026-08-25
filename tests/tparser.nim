import std/unittest

import ../src/lexer
import ../src/parser
import ../src/ast


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
