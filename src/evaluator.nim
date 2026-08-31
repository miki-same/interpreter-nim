import ast
import objects
import std/options
import std/strutils
import results
export results

let
    TRUE = Object(objectType: OBoolean, boolValue: true)
    FALSE = Object(objectType: OBoolean, boolValue: false)
    NULL = Object(objectType: ONull)

proc evalProgram(program: Program): Result[Object, string]
proc evalStatements(statements: seq[Statement]): Result[Object, string]
proc evalStatement(statement: Statement): Result[Object, string]
proc evalExpression(expression: Expression): Result[Object, string]

proc newError(format: string, args: varargs[string, `$`]): Object =
    return Object(objectType: OError, errorMessage: format % args)

proc isError(obj: Object): bool =
    if obj.objectType == OError:
        return true
    return false

proc eval*[T: Program or Statement or Expression](node: T): Result[Object, string] =
    when T is Program:
        return ok(?evalProgram(node))
    elif T is Statement:
        return ok(?evalStatement(node))
    elif T is Expression:
        return ok(?evalExpression(node))


proc nativeBoolToBooleanObject(input: bool): Object =
    if input:
        return TRUE
    else:
        return FALSE

proc evalBangOperatorExpression(right: Object): Object =
    if right == TRUE:
        return FALSE
    if right == FALSE:
        return TRUE
    if right == NULL:
        return TRUE
    return FALSE

proc evalMinusOperatorExpression(right: Object): Result[Object, string] =
    case right.objectType:
    of OInteger:
        var value = right.intValue
        return ok(Object(objectType: OInteger, intValue: -value))
    else:
        return ok(newError("unknown operator: -$1", right.getType))

proc evalPrefixExpression(operator: string, right: Object): Result[Object, string] =
    case operator:
    of "!":
        return ok(evalBangOperatorExpression(right))
    of "-":
        return ok(?evalMinusOperatorExpression(right))
    else:
        return err("invalid prefix operator")

proc evalIntegerInfixExpression(operator: string, left: Object,
        right: Object): Result[Object, string] =
    if left.getType != OInteger or right.getType != OInteger:
        return err("invalid object type")

    case operator:
    of "+":
        return ok(Object(objectType: OInteger,
                intValue: left.intValue+right.intValue))
    of "-":
        return ok(Object(objectType: OInteger,
                intValue: left.intValue-right.intValue))
    of "*":
        return ok(Object(objectType: OInteger,
                intValue: left.intValue*right.intValue))
    of "/":
        return ok(Object(objectType: OInteger,
                intValue: left.intValue div right.intValue))
    of ">":
        return ok(nativeBoolToBooleanObject(left.intValue > right.intValue))
    of "<":
        return ok(nativeBoolToBooleanObject(left.intValue < right.intValue))
    of "==":
        return ok(nativeBoolToBooleanObject(left.intValue == right.intValue))
    of "!=":
        return ok(nativeBoolToBooleanObject(left.intValue != right.intValue))
    else:
        return ok(newError("unknown operator: $1 $2 $3", left.getType, operator,
                right.getType))


proc evalInfixExpression(operator: string, left: Object, right: Object): Result[
        Object, string] =

    if left.getType == OInteger and right.getType == OInteger:
        return ok(?evalIntegerInfixExpression(operator, left, right))
    if left.getType != right.getType:
        return ok(newError("type mismatch: $1 $2 $3", left.getType, operator,
                right.getType))
    if operator == "==":
        return ok(nativeBoolToBooleanObject(left == right))
    if operator == "!=":
        return ok(nativeBoolToBooleanObject(left != right))
    return ok(newError("unknown operator: $1 $2 $3", left.getType, operator,
            right.getType))

proc isTruthy(obj: Object): bool =
    if obj == NULL or obj == FALSE:
        return false
    return true

proc evalExpression(expression: Expression): Result[Object, string] =
    case expression.kind:
    of ExIntegerLiteral:
        return ok(Object(objectType: OInteger, intValue: expression.intValue))
    of ExBooleanLiteral:
        return ok(nativeBoolToBooleanObject(expression.boolValue))
    of PrefixExpression:
        let right = ?evalExpression(expression.prefRight)
        if isError(right):
            return ok(right)

        return ok(?evalPrefixExpression(expression.prefOperator, right))
    of InfixExpression:
        let left = ?evalExpression(expression.infLeft)
        if isError(left):
            return ok(left)

        let right = ?evalExpression(expression.infRight)
        if isError(right):
            return ok(right)

        return ok(?evalInfixExpression(expression.infOperator, left, right))
    of IfExpression:
        let condition = ?evalExpression(expression.condition)
        if isError(condition):
            return ok(condition)

        if isTruthy(condition):
            return ok(?evalStatement(expression.consequence))
        elif expression.alternative.isSome:
            return ok(?evalStatement(expression.alternative.get))
        return ok(NULL)
    else:
        return err("invalid expression type")

proc evalBlockStatement(statement: Statement): Result[Object, string] =
    if statement.kind != StBlock:
        return err("invalid statement kind")

    var resultObject = NULL
    for statement in statement.statements:
        resultObject = ?evalStatement(statement)

        if resultObject.objectType == OReturn or resultObject.objectType == OError:
            return ok(resultObject)

    return ok(resultObject)

proc evalStatement(statement: Statement): Result[Object, string] =
    case statement.kind:
    of StExpression:
        return ok(?evalExpression(statement.expression))
    of StBlock:
        return ok(?evalBlockStatement(statement))
    of StReturn:
        let value = ?evalExpression(statement.returnValue)
        if isError(value):
            return ok(value)

        return ok(Object(objectType: OReturn, returnValue: value))
    else:
        return err("invalid statement type")

proc evalStatements(statements: seq[Statement]): Result[Object, string] =
    var resultObject = NULL
    for statement in statements:
        resultObject = ?evalStatement(statement)
        if resultObject.objectType == OReturn:
            return ok(resultObject.returnValue)

    return ok(resultObject)

proc evalProgram(program: Program): Result[Object, string] =
    var resultObject = NULL

    for statement in program.statements:
        resultObject = ?evalStatement(statement)

        if resultObject.objectType == OReturn:
            return ok(resultObject.returnValue)

        if resultObject.objectType == OError:
            return ok(resultObject)

    return ok(resultObject)
