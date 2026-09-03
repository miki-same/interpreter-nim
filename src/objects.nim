import ast
import std/strutils
import std/sequtils
import std/tables
import std/options
import std/hashes

type
    ObjectType* = enum
        OInteger = "INTEGER"
        OString = "STRING"
        OBoolean = "BOOLEAN"
        ONull = "NULL"
        OReturn = "RETURN_VALUE"
        OFunction = "FUNCTION"
        OBuiltIn = "BUILTIN"
        OArray = "ARRAY"
        OHash = "HASH"
        OError = "ERROR"

    HashPairObj = object
        key*: Object
        value*: Object
    HashPair* = ref HashPairObj

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
        of OArray:
            elements*: seq[Object]
        of OHash:
            pairs*: Table[Hash, HashPair]
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
    of OArray:
        result.add("[")
        result.add(self.elements.mapIt(it.inspect()).join(","))
        result.add("]")
    of OHash:
        var pairs: seq[string] = @[]
        for key, value in self.pairs:
            pairs.add(value.key.inspect() & ":" & value.value.inspect())
        result.add("{")
        result.add(pairs.join(","))
        result.add("}")
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
    of OArray:
        if len(a.elements) != len(b.elements):
            return false

        for i in 0..<len(a.elements):
            if a.elements[i] != b.elements[i]:
                return false
        return true
    of OHash:
        if len(a.pairs) != len(b.pairs):
            return false
        for key, value in a.pairs:
            if not key in b.pairs:
                return false
            let x = b.pairs[key]
            if b.pairs[key].key != a.pairs[key].key or b.pairs[key].value !=
                    a.pairs[key].value:
                return false
        return true

    of OError:
        return a.errorMessage == b.errorMessage

proc hash*(self: Object): Hash =
    case self.getType():
    of OBoolean:
        result = hash(self.boolValue) !& hash($self.getType())
    of OInteger:
        result = hash(self.intValue) !& hash($self.getType())
    of OString:
        result = hash(self.strValue) !& hash($self.getType())
    else:
        raise newException(ValueError, "unhashable object")


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
