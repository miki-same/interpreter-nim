import ast
import objects
import std/options
import std/strutils
import std/strformat
import std/enumerate
import std/tables
import results
export results

let
    TRUE = Object(objectType: OBoolean, boolValue: true)
    FALSE = Object(objectType: OBoolean, boolValue: false)
    NULL = Object(objectType: ONull)

proc evalProgram(program: Program, env: var Environment): Result[Object, string]
proc evalStatement(statement: Statement, env: var Environment): Result[Object, string]
proc evalExpression(expression: Expression, env: var Environment): Result[
        Object, string]

proc newError(format: string, args: varargs[string, `$`]): Object =
    return Object(objectType: OError, errorMessage: format % args)

proc isError(obj: Object): bool =
    if obj.objectType == OError:
        return true
    return false

let
    builtinLen = proc (args: varargs[
            Object]): Object =
        if len(args) != 1:
            return newError("wrong number of arguments. got=$1, want=$2", len(
                    args), 1)
        let arg = args[0]

        case arg.getType():
        of OString:
            return Object(objectType: OInteger, intValue: len(arg.strValue))
        of OArray:
            return Object(objectType: OInteger, intValue: len(arg.elements))
        else:
            return newError("argument to `len` not supported, got $1",
                    arg.getType())

    builtinStr = proc (args: varargs[
            Object]): Object =
        if len(args) != 1:
            return newError("wrong number of arguments. got=$1, want=$2", len(
                    args), 1)
        let arg = args[0]

        case arg.getType():
        of OString:
            return Object(objectType: OString, strValue: arg.strValue)
        of OInteger:
            return Object(objectType: OString, strValue: $arg.intValue)
        of OBoolean:
            let s = if(arg.boolValue): "true" else: "false"
            return Object(objectType: OString, strValue: s)
        of ONull:
            return Object(objectType: OString, strValue: "null")
        else:
            return newError("argument to `str` not supported, got $1",
                    arg.getType())
    builtinFirst = proc (args: varargs[
            Object]): Object =
        if len(args) != 1:
            return newError("wrong number of arguments. got=$1, want=$2", len(
                    args), 1)
        let arg = args[0]

        case arg.getType():
        of OArray:
            if len(arg.elements) == 0:
                return NULL
            return arg.elements[0]
        else:
            return newError("argument to `first` not supported, got $1",
                    arg.getType())
    builtinLast = proc (args: varargs[
            Object]): Object =
        if len(args) != 1:
            return newError("wrong number of arguments. got=$1, want=$2", len(
                    args), 1)
        let arg = args[0]

        case arg.getType():
        of OArray:
            if len(arg.elements) == 0:
                return NULL
            return arg.elements[^1]
        else:
            return newError("argument to `last` not supported, got $1",
                    arg.getType())
    builtinRest = proc (args: varargs[
            Object]): Object =
        if len(args) != 1:
            return newError("wrong number of arguments. got=$1, want=$2", len(
                    args), 1)
        let arg = args[0]

        case arg.getType():
        of OArray:
            if len(arg.elements) == 0:
                return NULL
            return Object(objectType: OArray, elements: arg.elements[1..^1])
        else:
            return newError("argument to `rest` not supported, got $1",
                    arg.getType())
    builtinPush = proc (args: varargs[
            Object]): Object =
        if len(args) != 2:
            return newError("wrong number of arguments. got=$1, want=$2", len(
                    args), 2)
        let arr = args[0]
        let element = args[1]

        case arr.getType():
        of OArray:
            var newElements = arr.elements
            newElements.add(element)
            return Object(objectType: OArray, elements: newElements)
        else:
            return newError("argument 1 to `push` not supported, got $1",
                    arr.getType())

let builtins = {
    "len": Object(objectType: OBuiltIn, fn: builtinLen),
    "str": Object(objectType: OBuiltIn, fn: builtinStr),
    "first": Object(objectType: OBuiltIn, fn: builtinFirst),
    "last": Object(objectType: OBuiltIn, fn: builtinLast),
    "rest": Object(objectType: OBuiltIn, fn: builtinRest),
    "push": Object(objectType: OBuiltIn, fn: builtinPush)
}.toTable


proc eval*[T: Program or Statement or Expression](node: T,
        env: var Environment): Result[Object, string] =
    when T is Program:
        return ok(?evalProgram(node, env))
    elif T is Statement:
        return ok(?evalStatement(node, env))
    elif T is Expression:
        return ok(?evalExpression(node, env))


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

proc evalStringInfixExpression(operator: string, left: Object,
        right: Object): Result[Object, string] =
    if left.getType != OString or right.getType != OString:
        return err("invalid object type")

    case operator:
    of "+":
        return ok(Object(objectType: OString,
                strValue: left.strValue & right.strValue))
    else:
        return ok(newError("unknown operator: $1 $2 $3", left.getType, operator,
                right.getType))

proc evalInfixExpression(operator: string, left: Object, right: Object): Result[
        Object, string] =

    if left.getType == OInteger and right.getType == OInteger:
        return ok(?evalIntegerInfixExpression(operator, left, right))
    if left.getType == OString and right.getType == OString:
        return ok(?evalStringInfixExpression(operator, left, right))
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

proc extendFunctionEnv(fn: Object, args: seq[Object]): Result[Environment, string] =
    if fn.getType() != OFunction:
        return err("not a function")
    var env = newEnclosedEnvironment(fn.env)

    if len(fn.parameters) != len(args):
        return err(fmt("need {len(fn.parameters)} parameters, but got {len(args)}"))

    for i, param in enumerate(fn.parameters):
        env.set(param.idValue, args[i])

    return ok(env)

proc unwrapReturnValue(obj: Object): Object =
    if obj.getType() == OReturn:
        return obj.returnValue

    return obj

proc applyFunction(fn: Object, args: seq[Object]): Result[Object, string] =
    if fn.getType() != OFunction and fn.getType() != OBuiltIn:
        return ok(newError("not a function: $1", fn.getType()))

    case fn.getType():
    of OFunction:
        let extendedEnvRes = extendFunctionEnv(fn, args)
        if extendedEnvRes.isErr:
            return ok(newError(extendedEnvRes.error))
        var extendedEnv = extendedEnvRes.value

        let evaluated = ?evalStatement(fn.body, extendedEnv)
        return ok(unwrapReturnValue(evaluated))
    of OBuiltIn:
        return ok(fn.fn(args))
    else:
        return err("unreachable")

proc applyIndex(arr: Object, index: Object): Result[Object, string] =
    if arr.getType() != OArray:
        return ok(newError("not a array: $1", arr.getType()))
    if index.getType() != OInteger:
        return ok(newError("not a integer: $1", index.getType()))

    if index.intValue < 0 or index.intValue >= len(arr.elements):
        return ok(NULL)

    return ok(arr.elements[index.intValue])

proc evalExpressions(exps: seq[Expression], env: var Environment): Result[seq[
        Object], string] =
    var values: seq[Object] = @[]
    for exp in exps:
        let evaluated = ?evalExpression(exp, env)
        if isError(evaluated):
            return ok(@[evaluated])
        values.add(evaluated)
    return ok(values)

proc evalExpression(expression: Expression, env: var Environment): Result[
        Object, string] =
    case expression.kind:
    of ExIdentifier:
        let val = env.get(expression.idValue)
        if val.isSome:
            return ok(val.get)

        if expression.idValue in builtins:
            return ok(builtins[expression.idValue])

        return ok(newError("identifier not found:$1", expression.idValue))
    of ExIntegerLiteral:
        return ok(Object(objectType: OInteger, intValue: expression.intValue))
    of ExStringLiteral:
        return ok(Object(objectType: OString, strValue: expression.strValue))
    of ExBooleanLiteral:
        return ok(nativeBoolToBooleanObject(expression.boolValue))
    of ExArrayLiteral:
        let elements = ?evalExpressions(expression.elements, env)
        if len(elements) == 1 and elements[0].getType() == OError:
            return ok(elements[0])

        return ok(Object(objectType: OArray, elements: elements))
    of ExFunctionLiteral:
        let fn = Object(objectType: OFunction,
                parameters: expression.parameters, body: expression.body, env: env)
        return ok(fn)
    of PrefixExpression:
        let right = ?evalExpression(expression.prefRight, env)
        if isError(right):
            return ok(right)

        return ok(?evalPrefixExpression(expression.prefOperator, right))
    of InfixExpression:
        let left = ?evalExpression(expression.infLeft, env)
        if isError(left):
            return ok(left)

        let right = ?evalExpression(expression.infRight, env)
        if isError(right):
            return ok(right)

        return ok(?evalInfixExpression(expression.infOperator, left, right))
    of IfExpression:
        let condition = ?evalExpression(expression.condition, env)
        if isError(condition):
            return ok(condition)

        if isTruthy(condition):
            return ok(?evalStatement(expression.consequence, env))
        elif expression.alternative.isSome:
            return ok(?evalStatement(expression.alternative.get, env))
        return ok(NULL)
    of CallExpression:
        let function = ?evalExpression(expression.function, env)
        if isError(function):
            return ok(function)

        let args = ?evalExpressions(expression.arguments, env)
        if len(args) == 1 and args[0].objectType == OError:
            return ok(args[0])

        let res = ?applyFunction(function, args)

        return ok(res)
    of IndexExpression:
        let arr = ?evalExpression(expression.idxLeft, env)
        if isError(arr):
            return ok(arr)
        if arr.getType() != OArray:
            return ok(newError("argument for index not supported, got $1",
                    arr.getType()))

        let index = ?evalExpression(expression.index, env)
        if isError(index):
            return ok(index)
        if index.getType() != OInteger:
            return ok(newError("argument for index not supported, got $1",
                    index.getType()))

        return ok(?applyIndex(arr, index))

proc evalBlockStatement(statement: Statement, env: var Environment): Result[
        Object, string] =
    if statement.kind != StBlock:
        return err("invalid statement kind")

    var resultObject = NULL
    for statement in statement.statements:
        resultObject = ?evalStatement(statement, env)

        if resultObject.objectType == OReturn or resultObject.objectType == OError:
            return ok(resultObject)

    return ok(resultObject)

proc evalStatement(statement: Statement, env: var Environment): Result[Object, string] =
    case statement.kind:
    of StExpression:
        return ok(?evalExpression(statement.expression, env))
    of StBlock:
        return ok(?evalBlockStatement(statement, env))
    of StReturn:
        let value = ?evalExpression(statement.returnValue, env)
        if isError(value):
            return ok(value)

        return ok(Object(objectType: OReturn, returnValue: value))
    of StLet:
        let value = ?evalExpression(statement.value, env)
        if isError(value):
            return ok(value)

        return ok(env.set(statement.name.idValue, value))

proc evalProgram(program: Program, env: var Environment): Result[Object, string] =
    var resultObject = NULL

    for statement in program.statements:
        resultObject = ?evalStatement(statement, env)

        if resultObject.objectType == OReturn:
            return ok(resultObject.returnValue)

        if resultObject.objectType == OError:
            return ok(resultObject)

    return ok(resultObject)
