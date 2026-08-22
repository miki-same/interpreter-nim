import lexer
import token

const PROMPT=">> "

proc start*()=
    while true:
        stdout.write(PROMPT)
        let scanned=stdin.readLine
        if len(scanned)==0:
            return

        var lexer=newLexer(scanned)

        while true:
            let token=lexer.nextToken()
            if token.kind == TokenType.EOF:
                break

            echo token