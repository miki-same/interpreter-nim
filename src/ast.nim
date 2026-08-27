import token

type StatementKind* = enum
    StLet
    StReturn
    StExpression

type ExpressionKind* = enum
    ExIdentifier
    ExIntegerLiteral
    PrefixExpression
    InfixExpression

type
    ExpressionObject* = object
        token*: Token
        case kind*: ExpressionKind
        of ExIdentifier:
            idValue*: string
        of ExIntegerLiteral:
            intValue*: int
        of PrefixExpression:
            prefOperator*: string
            prefRight*: Expression
        of InfixExpression:
            infOperator*: string
            infLeft*: Expression
            infRight*: Expression
    Expression* = ref ExpressionObject

proc tokenLiteral*(self: Expression): string =
    return ""

proc display(self: Expression): string =
    case self.kind:
    of ExIdentifier:
        return self.idValue
    of ExIntegerLiteral:
        return $self.intValue
    of PrefixExpression:
        result.add("(")
        result.add(self.prefOperator)
        result.add(self.prefRight.display())
        result.add(")")
    of InfixExpression:
        result.add("(")
        result.add(self.infLeft.display())
        result.add(self.infOperator)
        result.add(self.infRight.display())
        result.add(")")

type Statement* = object
    case kind*: StatementKind
    of StLet:
        name*: Expression
        value*: Expression
    of StReturn:
        returnValue*: Expression
    of StExpression:
        expression*: Expression


proc tokenLiteral*(self: Statement): string =
    case self.kind:
        of StLet:
            return "let"
        of StReturn:
            return "return"
        of StExpression:
            return self.expression.tokenLiteral()

proc display(self: Statement): string =
    case self.kind:
    of StLet:
        result.add(self.tokenLiteral & " ")
        result.add(self.name.display() & " = " & self.value.display())
    of StReturn:
        result.add(self.tokenLiteral & " ")
        result.add(self.returnValue.display())
    of StExpression:
        result.add(self.expression.display())
    result.add(";")

type Program* = object
    statements*: seq[Statement]

proc tokenLiteral*(self: Program): string =
    if len(self.statements) > 0:
        return self.statements[0].tokenLiteral()

proc display*(self: Program): string =
    for statement in self.statements:
        result.add(statement.display())

type Precedence* = enum
    Lowest,
    Equals,
    LessGreater,
    Sum,
    Product,
    Prefix,
    Call
