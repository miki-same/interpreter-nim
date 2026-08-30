import std/unittest

import ../src/lexer
import ../src/parser
import ../src/objects

include ../src/evaluator


proc evaluate(input: string): Object =
    var lexer = newLexer(input)
    var parser = newParser(lexer)
    let program = parser.parseProgram()
    require program.isOk

    let res = eval(program.value)
    require res.isOk

    return res.value


suite "Evaluator.eval":

    test "evaluates integer programs to integer objects":
        let cases = [
            (input: "5", expected: 5),
            (input: "10", expected: 10),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OInteger
            check evaluated.intValue == testCase.expected

    test "evaluates boolean programs to boolean objects":
        let cases = [
            (input: "true", expected: true),
            (input: "false", expected: false),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OBoolean
            check evaluated.boolValue == testCase.expected
