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

    test "evaluates bang prefix expressions":
        let cases = [
            (input: "!true", expected: false),
            (input: "!false", expected: true),
            (input: "!5", expected: false),
            (input: "!!true", expected: true),
            (input: "!!false", expected: false),
            (input: "!!5", expected: true),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OBoolean
            check evaluated.boolValue == testCase.expected

    test "evaluates minus prefix expressions":
        let cases = [
            (input: "-5", expected: -5),
            (input: "-10", expected: -10),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OInteger
            check evaluated.intValue == testCase.expected

    test "evaluates integer infix expressions":
        let cases = [
            (input: "5 + 5 + 5 + 5 - 10", expected: 10),
            (input: "2 * 2 * 2 * 2 * 2", expected: 32),
            (input: "-50 + 100 + -50", expected: 0),
            (input: "5 * 2 + 10", expected: 20),
            (input: "5 + 2 * 10", expected: 25),
            (input: "20 + 2 * -10", expected: 0),
            (input: "50 / 2 * 2 + 10", expected: 60),
            (input: "2 * (5 + 10)", expected: 30),
            (input: "3 * 3 * 3 + 10", expected: 37),
            (input: "3 * (3 * 3) + 10", expected: 37),
            (input: "(5 + 10 * 2 + 15 / 3) * 2 + -10", expected: 50),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OInteger
            check evaluated.intValue == testCase.expected

    test "evaluates comparison infix expressions":
        let cases = [
            (input: "1 < 2", expected: true),
            (input: "1 > 2", expected: false),
            (input: "1 < 1", expected: false),
            (input: "1 > 1", expected: false),
            (input: "1 == 1", expected: true),
            (input: "1 != 1", expected: false),
            (input: "1 == 2", expected: false),
            (input: "1 != 2", expected: true),
            (input: "true == true", expected: true),
            (input: "false == false", expected: true),
            (input: "true == false", expected: false),
            (input: "true != false", expected: true),
            (input: "(1 < 2) == true", expected: true),
            (input: "(1 < 2) == false", expected: false),
            (input: "(1 > 2) == true", expected: false),
            (input: "(1 > 2) == false", expected: true),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OBoolean
            check evaluated.boolValue == testCase.expected
