import token

type Lexer* = object
    input*: string
    position*: int
    readPosition*: int
    ch*: char

proc readChar*(self: var Lexer) =
    if self.readPosition >= len(self.input):
        self.ch = '\0'
    else:
        self.ch = self.input[self.readPosition]

    self.position = self.readPosition
    self.readPosition+=1

proc peekChar(self: Lexer): char =
    if self.readPosition >= len(self.input):
        return '\0'

    return self.input[self.readPosition]


proc skipWhiteSpace(self: var Lexer) =
    while self.ch == ' ' or self.ch == '\t' or self.ch == '\n' or self.ch == '\r':
        self.readChar()


proc isLetter(ch: char): bool =
    return ('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z') or (ch == '_')

proc isDigit(ch: char): bool =
    return '0' <= ch and ch <= '9'

proc readIdentifier(self: var Lexer): string =
    let position = self.position
    while isLetter(self.ch):
        self.readChar()

    return self.input[position..<self.position]

proc readNumber(self: var Lexer): string =
    let position = self.position
    while isDigit(self.ch):
        self.readChar()

    return self.input[position..<self.position]


proc nextToken*(self: var Lexer): Token =
    var token: Token

    self.skipWhiteSpace()

    case self.ch
        of '=':
            if self.peekChar() == '=':
                token = Token(kind: TokenType.Eq, literal: "==")
                self.readChar()
            else:
                token = Token(kind: TokenType.Assign, literal: "=")
        of ';':
            token = Token(kind: TokenType.SemiColon, literal: ";")
        of '(':
            token = Token(kind: TokenType.LParen, literal: "(")
        of ')':
            token = Token(kind: TokenType.RParen, literal: ")")
        of ',':
            token = Token(kind: TokenType.Comma, literal: ",")
        of '+':
            token = Token(kind: TokenType.Plus, literal: "+")
        of '-':
            token = Token(kind: TokenType.Minus, literal: "-")
        of '!':
            if self.peekChar() == '=':
                token = Token(kind: TokenType.NotEq, literal: "!=")
                self.readChar()
            else:
                token = Token(kind: TokenType.Bang, literal: "!")
        of '*':
            token = Token(kind: TokenType.Asterisk, literal: "*")
        of '/':
            token = Token(kind: TokenType.Slash, literal: "/")
        of '<':
            token = Token(kind: TokenType.Lt, literal: "<")
        of '>':
            token = Token(kind: TokenType.Gt, literal: ">")
        of '{':
            token = Token(kind: TokenType.LBrace, literal: "{")
        of '}':
            token = Token(kind: TokenType.RBrace, literal: "}")
        of '\0':
            token = Token(kind: TokenType.EOF, literal: "")
        else:
            if isLetter(self.ch):
                token.literal = self.readIdentifier()
                token.kind = lookUpIdent(token.literal)

                return token

            elif isDigit(self.ch):
                token.literal = self.readNumber()
                token.kind = TokenType.Int

                return token
            else:
                token.literal = $self.ch
                token.kind = TokenType.Illegal

    self.readChar()

    return token

proc newLexer*(input: string): Lexer =
    var lexer = Lexer(input: input)
    lexer.readChar()

    return lexer
