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
