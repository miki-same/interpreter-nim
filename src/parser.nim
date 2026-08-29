import results
export results
import lexer
import token
import ast
import std/tables
import std/strutils
import std/options

proc getPrecedence(token: Token): Precedence =
    case token.kind:
    of Eq:
        result = Equals
    of NotEq:
        result = Equals
    of Lt:
        result = LessGreater
    of Gt:
        result = LessGreater
    of Plus:
        result = Sum
    of Minus:
        result = Sum
    of Slash:
        result = Product
    of Asterisk:
        result = Product
    else:
        result = Lowest

type
    Parser* = object
        lexer: Lexer
        curToken: Token
        peekToken: Token
        prefixParseFns: Table[TokenType, PrefixParseFn]
        infixParseFns: Table[TokenType, InfixParseFn]

    InfixParseFn* = proc(self: var Parser, left: Expression): Result[Expression, string]
    PrefixParseFn* = proc(self: var Parser): Result[Expression, string]

proc peekPrecedence(self: Parser): Precedence =
    return getPrecedence(self.peekToken)

proc curPrecedence(self: Parser): Precedence =
    return getPrecedence(self.curToken)

proc registerPrefix(self: var Parser, kind: TokenType, fn: PrefixParseFn) =
    self.prefixParseFns[kind] = fn

proc registerInfix(self: var Parser, kind: TokenType, fn: InfixParseFn) =
    self.infixParseFns[kind] = fn

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

proc parseExpression(self: var Parser, precedence: Precedence): Result[
        Expression, string] =
    if not(self.curToken.kind in self.prefixParseFns):
        return err("invalid token type")
    let prefix = self.prefixParseFns[self.curToken.kind]
    var leftExp = ?prefix(self)

    while not self.peekTokenIs(SemiColon) and precedence < self.peekPrecedence():
        if not (self.peekToken.kind in self.infixParseFns):
            return err("invalid token type")
        let infix = self.infixParseFns[self.peekToken.kind]

        self.nextToken()

        leftExp = ?self.infix(leftExp)

    return ok(leftExp)


proc parseExpressionStatement(self: var Parser): Result[Statement, string] =
    var statement = Statement(kind: StExpression)

    statement.expression = ?self.parseExpression(Lowest)

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
        of Bang:
            return ok(?self.parseExpressionStatement())
        of Minus:
            return ok(?self.parseExpressionStatement())
        of True:
            return ok(?self.parseExpressionStatement())
        of LParen:
            return ok(?self.parseExpressionStatement())
        of False:
            return ok(?self.parseExpressionStatement())
        of If:
            return ok(?self.parseExpressionStatement())
        of Function:
            return ok(?self.parseExpressionStatement())
        else:
            return err("expected a statement, but found " & describe(self.curToken))

proc parseBlockStatement(self: var Parser): Result[Statement, string] =
    var blockStatement = Statement(kind: StBlock, token: self.curToken)
    self.nextToken()

    while not (self.curTokenIs(RBrace)) and not (self.curTokenIs(EOF)):
        let statement = ?self.parseStatement()
        blockStatement.statements.add(statement)

        self.nextToken()

    return ok(blockStatement)


proc parseProgram*(self: var Parser): Result[Program, string] =
    var program = Program()

    while self.curToken.kind != EOF:
        let statement = ?self.parseStatement()
        program.statements.add(statement)
        self.nextToken()

    return ok(program)

proc parseIdentifier(self: var Parser): Result[Expression, string] =
    return ok(Expression(kind: ExIdentifier, token: self.curToken,
            idValue: self.curToken.literal))

proc parseIntegerLiteral(self: var Parser): Result[Expression, string] =
    return ok(Expression(kind: ExIntegerLiteral, token: self.curToken,
            intValue: self.curToken.literal.parseInt))

proc parseBoolean(self: var Parser): Result[Expression, string] =
    let value =
        case self.curToken.literal
        of "true":
            true
        of "false":
            false
        else:
            return err("invalid literal")
    return ok(Expression(kind: ExBooleanLiteral, token: self.curToken,
            boolValue: value))

proc parseGroupedExpression(self: var Parser): Result[Expression, string] =
    self.nextToken()
    let exp = ?self.parseExpression(Lowest)

    if not self.expectPeek(RParen):
        return err("paren not closed")

    return ok(exp)

proc parseIfExpression(self: var Parser): Result[Expression, string] =
    var expression = Expression(kind: IfExpression, token: self.curToken)
    if not self.expectPeek(LParen):
        return err("invalid syntax: expected ( but found " &
                self.curToken.literal)

    self.nextToken()
    expression.condition = ?self.parseExpression(Lowest)

    if not self.expectPeek(RParen):
        return err("invalid syntax: expected ) but found " &
                self.curToken.literal)

    if not self.expectPeek(LBrace):
        return err("invalid syntax: expected { but found " &
                self.curToken.literal)

    expression.consequence = ?self.parseBlockStatement()

    if not self.curTokenIs(RBrace):
        return err("invalid syntax: expected } but found " &
                self.curToken.literal)

    if self.peekTokenIs(Else):
        self.nextToken()

        if not self.expectPeek(LBrace):
            return err("invalid syntax: expected { but found" &
                    self.curToken.literal)

        expression.alternative = some(?self.parseBlockStatement())

    if not self.curTokenIs(RBrace):
        return err("invalid syntax: expected } but found " &
                self.curToken.literal)


    return ok(expression)

proc parseFunctionParameters(self: var Parser): Result[seq[Expression], string] =
    var identifiers: seq[Expression] = @[]
    if self.peekTokenIs(RParen):
        self.nextToken()
        return ok(identifiers)

    self.nextToken()

    let ident = Expression(kind: ExIdentifier, token: self.curToken,
            idValue: self.curToken.literal)
    identifiers.add(ident)

    while self.peekTokenIs(Comma):
        self.nextToken()
        self.nextToken()
        let ident = Expression(kind: ExIdentifier, token: self.curToken,
                idValue: self.curToken.literal)
        identifiers.add(ident)

    if not self.expectPeek(RParen):
        return err("invalid syntax: expected ) but found " &
                self.curToken.literal)

    return ok(identifiers)

proc parseFunctionLiteral(self: var Parser): Result[Expression, string] =
    var literal = Expression(kind: ExFunctionLiteral, token: self.curToken)

    if not self.expectPeek(LParen):
        return err("invalid syntax: expected ( but found" &
                self.curToken.literal)

    literal.parameters = ?self.parseFunctionParameters()

    if not self.expectPeek(LBrace):
        return err("invalid syntax: expected ( but found" &
                self.curToken.literal)

    literal.body = ?self.parseBlockStatement()

    return ok(literal)

proc parsePrefixExpression(self: var Parser): Result[Expression, string] =
    var expression = Expression(kind: PrefixExpression, token: self.curToken,
            prefOperator: self.curToken.literal)

    self.nextToken()
    expression.prefRight = ?self.parseExpression(Prefix)

    return ok(expression)

proc parseInfixExpression(self: var Parser, left: Expression): Result[
        Expression, string] =
    var expression = Expression(kind: InfixExpression, token: self.curToken,
            infOperator: self.curToken.literal, infLeft: left)

    let precedence = self.curPrecedence()
    self.nextToken()
    expression.infRight = ?self.parseExpression(precedence)

    return ok(expression)

proc newParser*(lexer: Lexer): Parser =
    var parser = Parser(lexer: lexer)

    parser.prefixParseFns = initTable[TokenType, PrefixParseFn]()
    parser.registerPrefix(Ident, parseIdentifier)
    parser.registerPrefix(Int, parseIntegerLiteral)
    parser.registerPrefix(True, parseBoolean)
    parser.registerPrefix(False, parseBoolean)
    parser.registerPrefix(LParen, parseGroupedExpression)
    parser.registerPrefix(Bang, parsePrefixExpression)
    parser.registerPrefix(Minus, parsePrefixExpression)
    parser.registerPrefix(If, parseIfExpression)
    parser.registerPrefix(Function, parseFunctionLiteral)

    parser.infixParseFns = initTable[TokenType, InfixParseFn]()
    parser.registerInfix(Plus, parseInfixExpression)
    parser.registerInfix(Minus, parseInfixExpression)
    parser.registerInfix(Slash, parseInfixExpression)
    parser.registerInfix(Asterisk, parseInfixExpression)
    parser.registerInfix(Eq, parseInfixExpression)
    parser.registerInfix(NotEq, parseInfixExpression)
    parser.registerInfix(Lt, parseInfixExpression)
    parser.registerInfix(Gt, parseInfixExpression)

    parser.nextToken()
    parser.nextToken()

    return parser
