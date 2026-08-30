type ObjectType* = enum
    OInteger = "INTEGER"
    OBoolean = "BOOLEAN"
    ONull = "NULL"

type Object* = object
    case objectType*: ObjectType
    of OInteger:
        intValue*: int
    of OBoolean:
        boolValue*: bool
    of ONull:
        discard

proc inspect*(self: Object): string =
    case self.objectType:
    of OInteger:
        return $self.intValue
    of OBoolean:
        return $self.boolValue
    of ONull:
        return "null"

proc getType*(self: Object): ObjectType =
    return self.objectType

proc `==`*(a, b: Object): bool =
    if a.objectType != b.objectType:
        return false

    case a.objectType:
    of OInteger:
        return a.intValue == b.intValue
    of OBoolean:
        return a.boolValue == b.boolValue
    else:
        return false
