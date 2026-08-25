import results
export results
import lexer
import token
import ast

type Parser* = object
    lexer: Lexer
    curToken: Token
    peekToken: Token

proc nextToken(self: var Parser) =
    self.curToken = self.peekToken
    self.peekToken = self.lexer.nextToken()

proc curTokenIs(self: Parser, kind: TokenType): bool =
    return self.curToken.kind == kind

proc peekTokenIs(self: Parser, kind: TokenType): bool =
    return self.peekToken.kind == kind

proc describe(token: Token): string =
    if token.kind == EOF:
        return "end of input"
    if token.kind == Illegal:
        return "invalid token '" & token.literal & "'"
    return "'" & token.literal & "' (" & $token.kind & ")"

proc expectPeek(self: var Parser, kind: TokenType): bool =
    if self.peekTokenIs(kind):
        self.nextToken()
        return true
    else:
        return false

proc parseLetStatement(self: var Parser): Result[Statement, string] =
    var statement = Statement(kind: StLet)

    if not self.expectPeek(Ident):
        return err("expected an identifier after 'let', but found " &
            describe(self.peekToken))
    statement.name = Expression(kind: ExIdentifier, token: self.curToken,
            value: self.curToken.literal)

    while not self.curTokenIs(SemiColon):
        self.nextToken()

    return ok(statement)

proc parseReturnStatement(self: var Parser): Result[Statement, string] =
    var statement = Statement(kind: StReturn)

    while not self.curTokenIs(SemiColon):
        self.nextToken()

    return ok(statement)

proc parseStatement(self: var Parser): Result[Statement, string] =
    case self.curToken.kind:
        of Let:
            return ok(?self.parseLetStatement())
        of Return:
            return ok(?self.parseReturnStatement())
        else:
            return err("expected a statement, but found " & describe(self.curToken))

proc parseProgram*(self: var Parser): Result[Program, string] =
    var program = Program()

    while self.curToken.kind != EOF:
        let statement = ?self.parseStatement()
        program.statements.add(statement)
        self.nextToken()

    return ok(program)

proc newParser*(lexer: Lexer): Parser =
    var parser = Parser(lexer: lexer)
    parser.nextToken()
    parser.nextToken()

    return parser
