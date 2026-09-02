import std/[options, unittest]

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

    test "parses complete let statements":
        let input = """
let x = 5;
let y = true;
let foobar = y;
"""

        var lexer = newLexer(input)
        var parser = newParser(lexer)
        let parsed = parser.parseProgram()

        if parsed.isErr:
            checkpoint("parse error: " & parsed.error)
        require parsed.isOk

        let program = parsed.value
        require program.statements.len == 3

        let integerBinding = program.statements[0]
        require integerBinding.kind == StLet
        require integerBinding.name.kind == ExIdentifier
        check integerBinding.name.idValue == "x"
        require not integerBinding.value.isNil
        require integerBinding.value.kind == ExIntegerLiteral
        check integerBinding.value.intValue == 5

        let booleanBinding = program.statements[1]
        require booleanBinding.kind == StLet
        require booleanBinding.name.kind == ExIdentifier
        check booleanBinding.name.idValue == "y"
        require not booleanBinding.value.isNil
        require booleanBinding.value.kind == ExBooleanLiteral
        check booleanBinding.value.boolValue

        let identifierBinding = program.statements[2]
        require identifierBinding.kind == StLet
        require identifierBinding.name.kind == ExIdentifier
        check identifierBinding.name.idValue == "foobar"
        require not identifierBinding.value.isNil
        require identifierBinding.value.kind == ExIdentifier
        check identifierBinding.value.idValue == "y"

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

    test "parses complete return statements":
        let input = """
return 5;
return true;
return foobar;
"""

        var lexer = newLexer(input)
        var parser = newParser(lexer)
        let parsed = parser.parseProgram()

        if parsed.isErr:
            checkpoint("parse error: " & parsed.error)
        require parsed.isOk

        let program = parsed.value
        require program.statements.len == 3

        let integerReturn = program.statements[0]
        require integerReturn.kind == StReturn
        require not integerReturn.returnValue.isNil
        require integerReturn.returnValue.kind == ExIntegerLiteral
        check integerReturn.returnValue.intValue == 5

        let booleanReturn = program.statements[1]
        require booleanReturn.kind == StReturn
        require not booleanReturn.returnValue.isNil
        require booleanReturn.returnValue.kind == ExBooleanLiteral
        check booleanReturn.returnValue.boolValue

        let identifierReturn = program.statements[2]
        require identifierReturn.kind == StReturn
        require not identifierReturn.returnValue.isNil
        require identifierReturn.returnValue.kind == ExIdentifier
        check identifierReturn.returnValue.idValue == "foobar"

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

    test "parses a string literal expression statement":
        let input = "\"hello world\";"

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
        check expression.kind == ExStringLiteral
        check expression.strValue == "hello world"

    test "parses boolean literal expression statements":
        let cases = [
            (input: "true;", value: true),
            (input: "false;", value: false),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            var lexer = newLexer(testCase.input)
            var parser = newParser(lexer)
            let parsed = parser.parseProgram()

            if parsed.isErr:
                checkpoint("parse error: " & parsed.error)
            require parsed.isOk

            let program = parsed.value
            require program.statements.len == 1
            require program.statements[0].kind == StExpression

            let expression = program.statements[0].expression
            check expression.kind == ExBooleanLiteral
            check expression.boolValue == testCase.value

    test "parses an if expression":
        let input = "if (x < y) { x }"

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
        require expression.kind == IfExpression

        require expression.condition.kind == InfixExpression
        check expression.condition.infOperator == "<"
        require expression.condition.infLeft.kind == ExIdentifier
        check expression.condition.infLeft.idValue == "x"
        require expression.condition.infRight.kind == ExIdentifier
        check expression.condition.infRight.idValue == "y"

        require expression.consequence.kind == StBlock
        require expression.consequence.statements.len == 1
        let consequence = expression.consequence.statements[0]
        require consequence.kind == StExpression
        require consequence.expression.kind == ExIdentifier
        check consequence.expression.idValue == "x"

        check expression.alternative.isNone

    test "parses an if-else expression":
        let input = "if (x < y) { x } else { y }"

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
        require expression.kind == IfExpression

        require expression.condition.kind == InfixExpression
        check expression.condition.infOperator == "<"
        require expression.condition.infLeft.kind == ExIdentifier
        check expression.condition.infLeft.idValue == "x"
        require expression.condition.infRight.kind == ExIdentifier
        check expression.condition.infRight.idValue == "y"

        require expression.consequence.kind == StBlock
        require expression.consequence.statements.len == 1
        let consequence = expression.consequence.statements[0]
        require consequence.kind == StExpression
        require consequence.expression.kind == ExIdentifier
        check consequence.expression.idValue == "x"

        require expression.alternative.isSome
        let alternative = expression.alternative.get
        require alternative.kind == StBlock
        require alternative.statements.len == 1
        let alternativeStatement = alternative.statements[0]
        require alternativeStatement.kind == StExpression
        require alternativeStatement.expression.kind == ExIdentifier
        check alternativeStatement.expression.idValue == "y"

    test "parses a function literal":
        let input = "fn(x,y) {x+y;}"

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
        require expression.kind == ExFunctionLiteral
        require expression.parameters.len == 2
        require expression.parameters[0].kind == ExIdentifier
        check expression.parameters[0].idValue == "x"
        require expression.parameters[1].kind == ExIdentifier
        check expression.parameters[1].idValue == "y"

    test "parses a call expression":
        let input = "add(1,2*3,4+5);"

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
        require expression.kind == CallExpression
        require expression.function.kind == ExIdentifier
        check expression.function.idValue == "add"
        require expression.arguments.len == 3

        require expression.arguments[0].kind == ExIntegerLiteral
        check expression.arguments[0].intValue == 1

        require expression.arguments[1].kind == InfixExpression
        check expression.arguments[1].infOperator == "*"
        require expression.arguments[1].infLeft.kind == ExIntegerLiteral
        check expression.arguments[1].infLeft.intValue == 2
        require expression.arguments[1].infRight.kind == ExIntegerLiteral
        check expression.arguments[1].infRight.intValue == 3

        require expression.arguments[2].kind == InfixExpression
        check expression.arguments[2].infOperator == "+"
        require expression.arguments[2].infLeft.kind == ExIntegerLiteral
        check expression.arguments[2].infLeft.intValue == 4
        require expression.arguments[2].infRight.kind == ExIntegerLiteral
        check expression.arguments[2].infRight.intValue == 5

    test "parses prefix expressions":
        let cases = [
            (input: "!5", operator: "!", displayed: "(!5)"),
            (input: "-15", operator: "-", displayed: "(-15)"),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            var lexer = newLexer(testCase.input)
            var parser = newParser(lexer)
            let parsed = parser.parseProgram()

            if parsed.isErr:
                checkpoint("parse error: " & parsed.error)
            require parsed.isOk

            let program = parsed.value
            require program.statements.len == 1
            require program.statements[0].kind == StExpression

            let expression = program.statements[0].expression
            check expression.kind == PrefixExpression
            check expression.prefOperator == testCase.operator
            check program.display() == testCase.displayed

    test "parses infix expressions":
        let cases = [
            (input: "5 + 5", operator: "+"),
            (input: "5 - 5", operator: "-"),
            (input: "5 * 5", operator: "*"),
            (input: "5 / 5", operator: "/"),
            (input: "5 > 5", operator: ">"),
            (input: "5 < 5", operator: "<"),
            (input: "5 == 5", operator: "=="),
            (input: "5 != 5", operator: "!="),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            var lexer = newLexer(testCase.input)
            var parser = newParser(lexer)
            let parsed = parser.parseProgram()

            if parsed.isErr:
                checkpoint("parse error: " & parsed.error)
            require parsed.isOk

            let program = parsed.value
            require program.statements.len == 1
            require program.statements[0].kind == StExpression

            let expression = program.statements[0].expression
            require expression.kind == InfixExpression
            check expression.infOperator == testCase.operator
            require expression.infLeft.kind == ExIntegerLiteral
            check expression.infLeft.intValue == 5
            require expression.infRight.kind == ExIntegerLiteral
            check expression.infRight.intValue == 5

    test "respects operator precedence":
        let cases = [
            (input: "-a * b", displayed: "((-a)*b)"),
            (input: "!-a", displayed: "(!(-a))"),
            (input: "a + b + c", displayed: "((a+b)+c)"),
            (input: "a + b - c", displayed: "((a+b)-c)"),
            (input: "a * b * c", displayed: "((a*b)*c)"),
            (input: "a * b / c", displayed: "((a*b)/c)"),
            (input: "a + b / c", displayed: "(a+(b/c))"),
            (input: "a + b * c + d / e - f",
                displayed: "(((a+(b*c))+(d/e))-f)"),
            (input: "3 + 4; -5 * 5", displayed: "(3+4)((-5)*5)"),
            (input: "5 > 4 == 3 < 4", displayed: "((5>4)==(3<4))"),
            (input: "5 < 4 != 3 > 4", displayed: "((5<4)!=(3>4))"),
            (input: "3 + 4 * 5 == 3 * 1 + 4 * 5",
                displayed: "((3+(4*5))==((3*1)+(4*5)))"),
            (input: "3 > 5 == false", displayed: "((3>5)==false)"),
            (input: "3 < 5 == true", displayed: "((3<5)==true)"),
            (input: "1 + (2 + 3) + 4", displayed: "((1+(2+3))+4)"),
            (input: "(5 + 5) * 2", displayed: "((5+5)*2)"),
            (input: "2 / (5 + 5)", displayed: "(2/(5+5))"),
            (input: "-(5 + 5)", displayed: "(-(5+5))"),
            (input: "!(true == true)", displayed: "(!(true==true))"),
            (input: "a+add(b*c)+d", displayed: "((a+add((b*c)))+d)"),
            (input: "add(a,b,1,2*3,4+5,add(6,7*8))",
                displayed: "add(a,b,1,(2*3),(4+5),add(6,(7*8)))"),
        ]

        for testCase in cases:
            checkpoint("input: " & testCase.input)

            var lexer = newLexer(testCase.input)
            var parser = newParser(lexer)
            let parsed = parser.parseProgram()

            if parsed.isErr:
                checkpoint("parse error: " & parsed.error)
            require parsed.isOk

            check parsed.value.display() == testCase.displayed
