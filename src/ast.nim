import token

type StatementKind* = enum
    StLet
    StReturn

type ExpressionKind* = enum
    ExIdentifier

type Expression* = object
    case kind*: ExpressionKind
    of ExIdentifier:
        token*: Token
        value*: string

proc tokenLiteral*(self: Expression): string =
    return ""

proc display(self: Expression): string =
    case self.kind:
    of ExIdentifier:
        return self.value

type Statement* = object
    case kind*: StatementKind
    of StLet:
        name*: Expression
        value*: Expression
    of StReturn:
        returnValue*: Expression


proc tokenLiteral*(self: Statement): string =
    case self.kind:
        of StLet:
            return "let"
        of StReturn:
            return "return"

proc display(self: Statement): string =
    case self.kind:
    of StLet:
        result.add(self.tokenLiteral & " ")
        result.add(self.name.display() & " = " & self.value.display())
    of StReturn:
        result.add(self.tokenLiteral & " ")
        result.add(self.returnValue.display())
    result.add(";")

type Program* = object
    statements*: seq[Statement]

proc tokenLiteral*(self: Program): string =
    if len(self.statements) > 0:
        return self.statements[0].tokenLiteral()

proc display*(self: Program): string =
    for statement in self.statements:
        result.add(statement.display())
