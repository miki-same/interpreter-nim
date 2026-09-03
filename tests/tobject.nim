import std/unittest

import ../src/objects


suite "Object.hash":

    test "hashes string objects by their value":
        let helloWorld = Object(
            objectType: OString,
            strValue: "Hello World",
        )
        let sameHelloWorld = Object(
            objectType: OString,
            strValue: "Hello World",
        )
        let johnny = Object(
            objectType: OString,
            strValue: "My name is johnny",
        )

        check hash(helloWorld) == hash(sameHelloWorld)
        check hash(helloWorld) != hash(johnny)
