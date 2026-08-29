import lexer
import parser
import token
import ast

const PROMPT = ">> "

const FACE_PARTS="\"\"\"\"\"\""
const MONKEY_FACE="""
            __,__
   .--.  .-"     "-.  .--.
  / .. \/  .-. .-.  \/ .. \
 | |  '|  /   Y   \  |'  | |
 | \   \  \ 0 | 0 /  /   / |
  \ '- ,\.-""" & FACE_PARTS & """-./, -' /
   ''-' /_   ^ ^   _\ '-''
       |  \._   _./  |
       \   \ '~' /   /
        '._ '-=-' _.'
           '-----'
"""

proc start*() =
    while true:
        stdout.write(PROMPT)
        let scanned = stdin.readLine
        if len(scanned) == 0:
            return

        var lexer = newLexer(scanned)
        var parser = newParser(lexer)

        let program=parser.parseProgram()
        if program.isErr:
            echo MONKEY_FACE
            echo "Woops! We ran into some monkey business here!"
            echo "parser error:"
            echo "\t",program.error
            continue

        echo program.value.display()