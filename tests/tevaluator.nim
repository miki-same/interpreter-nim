import std/unittest

import ../src/ast
import ../src/lexer
import ../src/parser
import ../src/objects

import ../src/evaluator


proc evaluate(input: string): Object =
    var lexer = newLexer(input)
    var parser = newParser(lexer)
    let program = parser.parseProgram()
    require program.isOk

    var env = newEnvironment()

    let res = eval(program.value, env)
    if res.isErr:
        checkpoint("error: " & res.error)
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

    test "evaluates if expressions":
        let cases = [
            (input: "if (true) { 10 }", expected: 10),
            (input: "if (1) { 10 }", expected: 10),
            (input: "if (0) { 10 }", expected: 10),
            (input: "if (false) { 10 } else { 20 }", expected: 20),
            (input: "if (1 < 2) { 10 } else { 20 }", expected: 10),
            (input: "if (1 > 2) { 10 } else { 20 }", expected: 20),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OInteger
            check evaluated.intValue == testCase.expected

    test "evaluates if expressions without a matching branch to null":
        let cases = [
            "if (false) { 10 }",
            "if (1 > 2) { 10 }",
        ]

        for input in cases:
            checkpoint("input: " & input)

            let evaluated = evaluate(input)

            check evaluated.objectType == ONull

    test "evaluates return statements":
        let cases = [
            (input: "return 10;", expected: 10),
            (input: "return 10; 9;", expected: 10),
            (input: "return 2 * 5; 9;", expected: 10),
            (input: "if (10 > 1) { if (10 > 1) { return 10; } return 1; }",
                    expected: 10),
            (input: "9; return 2*5; 9;", expected: 10)
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OInteger
            check evaluated.intValue == testCase.expected

    test "evaluates let statements":
        let cases = [
            (input: "let a = 5; a;", expected: 5),
            (input: "let a = 5 * 5; a;", expected: 25),
            (input: "let a = 5; let b = a; b;", expected: 5),
            (input: "let a = 5; let b = a; let c = a + b + 5; c;",
                    expected: 15),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OInteger
            check evaluated.intValue == testCase.expected

    test "evaluates a function literal":
        let evaluated = evaluate("fn(x) { x + 2; };")

        check evaluated.objectType == OFunction
        require evaluated.parameters.len == 1
        check evaluated.parameters[0].idValue == "x"
        check evaluated.body.display() == "(x+2)"

    test "evaluates function calls":
        let cases = [
            (input: "let identity = fn(x) { x; }; identity(5);", expected: 5),
            (input: "let double = fn(x) { x * 2; }; double(5);", expected: 10),
            (input: "let add = fn(x, y) { x + y; }; add(5, 5);", expected: 10),
            (input: "let add = fn(x, y) { x + y; }; add(5, add(5, 5));",
                    expected: 15),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            let evaluated = evaluate(testCase.input)

            check evaluated.objectType == OInteger
            check evaluated.intValue == testCase.expected

    test "returns an error for an undefined identifier":
        let evaluated = evaluate("foobar")

        check evaluated.objectType == OError
        check evaluated.errorMessage == "identifier not found:foobar"

    test "returns errors for invalid operations":
        let cases = [
            (input: "5 + true;", expected: "type mismatch: INTEGER + BOOLEAN"),
            (input: "5 + true; 5;", expected: "type mismatch: INTEGER + BOOLEAN"),
            (input: "-true", expected: "unknown operator: -BOOLEAN"),
            (input: "true + false;", expected: "unknown operator: BOOLEAN + BOOLEAN"),
            (input: "5; true + false; 5",
                    expected: "unknown operator: BOOLEAN + BOOLEAN"),
            (input: "if (10 > 1) { true + false; }",
                    expected: "unknown operator: BOOLEAN + BOOLEAN"),
            (input: "if (10 > 1) { if (10 > 1) { return true + false; } return 1; }",
                    expected: "unknown operator: BOOLEAN + BOOLEAN"),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            var lexer = newLexer(testCase.input)
            var parser = newParser(lexer)
            let program = parser.parseProgram()
            require program.isOk

            var env = newEnvironment()

            let evaluated = eval(program.value, env)

            require evaluated.isok
            check evaluated.value.errorMessage == testCase.expected
