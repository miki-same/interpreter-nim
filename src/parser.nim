import results
export results
import lexer
import token
import ast
import std/tables
import std/strutils

type
    Parser* = object
        lexer: Lexer
        curToken: Token
        peekToken: Token
        prefixParseFns:Table[TokenType,PrefixParseFn]
        infixParseFns:Table[TokenType,InfixParseFn]

    InfixParseFn* =proc(left:ast.Expression):ast.Expression
    PrefixParseFn=proc(self:Parser):ast.Expression

proc registerPrefix(self:var Parser,kind:TokenType,fn:PrefixParseFn)=
    self.prefixParseFns[kind] =fn

proc registerInfix(self:var Parser,kind:TokenType,fn:InfixParseFn)=
    self.infixParseFns[kind] =fn

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
            idValue: self.curToken.literal)

    while not self.curTokenIs(SemiColon):
        self.nextToken()

    return ok(statement)

proc parseReturnStatement(self: var Parser): Result[Statement, string] =
    var statement = Statement(kind: StReturn)

    while not self.curTokenIs(SemiColon):
        self.nextToken()

    return ok(statement)

proc parseExpression(self:var Parser,precedence:Precedence):Result[Expression, string]=
    if not(self.curToken.kind in self.prefixParseFns):
        return err("invalid token type")
    let prefix=self.prefixParseFns[self.curToken.kind]
    let leftExp=prefix(self)

    return ok(leftExp)


proc parseExpressionStatement(self: var Parser): Result[Statement,string]=
    var statement = Statement(kind:StExpression)

    statement.expression= ?self.parseExpression(Lowest)

    if self.peekTokenIs(SemiColon):
        self.nextToken()
    
    return ok(statement)


proc parseStatement(self: var Parser): Result[Statement, string] =
    case self.curToken.kind:
        of Let:
            return ok(?self.parseLetStatement())
        of Return:
            return ok(?self.parseReturnStatement())
        of Ident:
            return ok(?self.parseExpressionStatement())
        of Int:
            return ok(?self.parseExpressionStatement())
        else:
            return err("expected a statement, but found " & describe(self.curToken))

proc parseProgram*(self: var Parser): Result[Program, string] =
    var program = Program()

    while self.curToken.kind != EOF:
        let statement = ?self.parseStatement()
        program.statements.add(statement)
        self.nextToken()

    return ok(program)

proc parseIdentifier(self:Parser):Expression=
    return Expression(kind:ExIdentifier,token:self.curToken,idValue:self.curToken.literal)

proc parseIntegerLiteral(self:Parser):Expression=
    return Expression(kind:ExIntegerLiteral,token:self.curToken,intValue:self.curToken.literal.parseInt)

proc newParser*(lexer: Lexer): Parser =
    var parser = Parser(lexer: lexer)

    parser.prefixParseFns=initTable[TokenType,PrefixParseFn]()
    parser.registerPrefix(Ident,parseIdentifier)
    parser.registerPrefix(Int,parseIntegerLiteral)

    parser.nextToken()
    parser.nextToken()

    return parser
