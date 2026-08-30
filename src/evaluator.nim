import ast
import objects
import results
export results

const
    TRUE = Object(objectType: OBoolean, boolValue: true)
    FALSE = Object(objectType: OBoolean, boolValue: false)
    NULL = Object(objectType: ONull)

proc nativeBoolToBooleanObject(input: bool): Object =
    if input:
        return TRUE
    else:
        return FALSE

proc evalBangOperatorExpression(right: Object): Object =
    case right.objectType:
    of OBoolean:
        if right.boolValue:
            return FALSE
        return TRUE
    of ONull:
        return TRUE
    else:
        return FALSE

proc evalMinusOperatorExpression(right: Object): Result[Object, string] =
    case right.objectType:
    of OInteger:
        var value = right.intValue
        return ok(Object(objectType: OInteger, intValue: -value))
    else:
        return ok(NULL)

proc evalPrefixExpression(operator: string, right: Object): Result[Object, string] =
    case operator:
    of "!":
        return ok(evalBangOperatorExpression(right))
    of "-":
        return ok(?evalMinusOperatorExpression(right))
    else:
        return err("invalid prefix operator")

proc evalExpression(expression: Expression): Result[Object, string] =
    case expression.kind:
    of ExIntegerLiteral:
        return ok(Object(objectType: OInteger, intValue: expression.intValue))
    of ExBooleanLiteral:
        return ok(nativeBoolToBooleanObject(expression.boolValue))
    of PrefixExpression:
        let right = ?evalExpression(expression.prefRight)
        return ok(?evalPrefixExpression(expression.prefOperator, right))
    else:
        return err("invalid expression type")

proc evalStatement(statement: Statement): Result[Object, string] =
    case statement.kind:
    of StExpression:
        return ok(?evalExpression(statement.expression))
    else:
        return err("invalid statement type")

proc evalStatements(statements: seq[Statement]): Result[Object, string] =
    var resultObject: Object
    for statement in statements:
        resultObject = ?evalStatement(statement)

    return ok(resultObject)


proc eval*[T: Program or Statement or Expression](node: T): Result[Object, string] =
    when T is Program:
        return ok(?evalStatements(node.statements))
    elif T is Statement:
        return ok(?evalStatement(node))
    elif T is Expression:
        return ok(?evalExpression(node))
