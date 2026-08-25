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

type Program* = object
                                statements*: seq[Statement]

proc tokenLiteral*(self: Program): string =
                                if len(self.statements) > 0:
                                                                return self.statements[0].tokenLiteral()
