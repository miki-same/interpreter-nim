import token

type StatementKind* = enum
        StLet

type ExpressionKind* = enum
        ExIdentifier

type Expression* = object
        case kind*: ExpressionKind
        of ExIdentifier:
                token*: Token
                value*: string

proc tokenLiteral*(self:Expression):string=
        return ""

type Statement* = object
        case kind*: StatementKind
        of StLet:
                name*: Expression
                value*: Expression

proc tokenLiteral*(self:Statement):string=
        return ""

type Program* = object
        statements*: seq[Statement]

proc tokenLiteral*(self:Program):string=
        if len(self.statements)>0:
                return self.statements[0].tokenLiteral()