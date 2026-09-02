import ast
import std/strutils
import std/sequtils
import std/tables
import std/options

type ObjectType* = enum
    OInteger = "INTEGER"
    OString = "STRING"
    OBoolean = "BOOLEAN"
    ONull = "NULL"
    OReturn = "RETURN_VALUE"
    OFunction = "FUNCTION"
    OBuiltIn = "BUILTIN"
    OError = "ERROR"

type
    ObjectObj* = object
        case objectType*: ObjectType
        of OInteger:
            intValue*: int
        of OString:
            strValue*: string
        of OBoolean:
            boolValue*: bool
        of ONull:
            discard
        of OReturn:
            returnValue*: Object
        of OFunction:
            parameters*: seq[Expression] #Identifiers
            body*: Statement             #BlockStatement
            env*: Environment
        of OBuiltIn:
            fn*: BuiltInFunction
        of OError:
            errorMessage*: string
    Object* = ref ObjectObj

    BuiltInFunction = proc(args: varargs[Object]): Object

    EnvironmentObject = object
        store*: Table[string, Object]
        outer: Option[Environment]
    Environment* = ref EnvironmentObject

proc inspect*(self: Object): string =
    case self.objectType:
    of OInteger:
        return $self.intValue
    of OString:
        return self.strValue
    of OBoolean:
        return $self.boolValue
    of ONull:
        return "null"
    of OReturn:
        return self.returnValue.inspect()
    of OFunction:
        result.add("fn")
        result.add("(")
        result.add(self.parameters.mapIt(it.idValue).join(","))
        result.add("){\n")
        result.add(self.body.display())
        result.add("\n}")
    of OBuiltIn:
        return "builtin function"
    of OError:
        return "ERROR: " & self.errorMessage

proc getType*(self: Object): ObjectType =
    return self.objectType

proc `==`*(a, b: Object): bool =
    if a.getType() != b.getType():
        return false

    case a.objectType:
    of OInteger:
        return a.intValue == b.intValue
    of OString:
        return a.strValue == b.strValue
    of OBoolean:
        return a.boolValue == b.boolValue
    of ONull:
        return true
    of OReturn:
        return a.returnValue == b.returnValue
    of OFunction:
        return a.parameters == b.parameters and a.body == b.body
    of OBuiltIn:
        return a.fn == b.fn
    of OError:
        return a.errorMessage == b.errorMessage

proc get*(self: Environment, name: string): Option[Object] =
    if name in self.store:
        return some(self.store[name])

    if self.outer.isSome:
        let res = self.outer.get().get(name)
        if res.isSome:
            return some(res.get())

    return none(Object)

proc set*(self: var Environment, name: string,
        val: Object): Object {.discardable.} =
    self.store[name] = val
    return val

proc newEnvironment*(): Environment =
    let store = initTable[string, Object]()
    return Environment(store: store)

proc newEnclosedEnvironment*(outer: Environment): Environment =
    var env = newEnvironment()
    env.outer = some(outer)

    return env
