import std/tables
import std/options
import objects

type Environment* = object
    store*: Table[string, Object]

proc get*(self: Environment, name: string): Option[Object] =
    if name in self.store:
        return some(self.store[name])

    return none(Object)

proc set*(self: var Environment, name: string, val: Object): Object =
    self.store[name] = val
    return val

proc newEnvironment*(): Environment =
    let store = initTable[string, Object]()
    return Environment(store: store)
