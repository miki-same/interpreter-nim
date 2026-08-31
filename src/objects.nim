type ObjectType* = enum
    OInteger = "INTEGER"
    OBoolean = "BOOLEAN"
    ONull = "NULL"
    OReturn = "RETURN_VALUE"
    OError = "ERROR"

type
    ObjectObj* = object
        case objectType*: ObjectType
        of OInteger:
            intValue*: int
        of OBoolean:
            boolValue*: bool
        of ONull:
            discard
        of OReturn:
            returnValue*: Object
        of OError:
            errorMessage*: string
    Object* = ref ObjectObj

proc inspect*(self: Object): string =
    case self.objectType:
    of OInteger:
        return $self.intValue
    of OBoolean:
        return $self.boolValue
    of ONull:
        return "null"
    of OReturn:
        return self.returnValue.inspect()
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
    of OBoolean:
        return a.boolValue == b.boolValue
    of ONull:
        return true
    of OReturn:
        return a.returnValue == b.returnValue
    of OError:
        return a.errorMessage == b.errorMessage
