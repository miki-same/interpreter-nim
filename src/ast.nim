import token
import std/options
import std/sequtils
import std/strutils

type StatementKind* = enum
    StLet
    StReturn
    StExpression
    StBlock

type ExpressionKind* = enum
    ExIdentifier
    ExIntegerLiteral
    ExBooleanLiteral
    ExFunctionLiteral
    PrefixExpression
    InfixExpression
    IfExpression

type
    ExpressionObject* = object
        token*: Token
        case kind*: ExpressionKind
        of ExIdentifier:
            idValue*: string
        of ExIntegerLiteral:
            intValue*: int
        of ExBooleanLiteral:
            boolValue*: bool
        of ExFunctionLiteral:
            parameters*: seq[Expression]
            body*: Statement
        of PrefixExpression:
            prefOperator*: string
            prefRight*: Expression
        of InfixExpression:
            infOperator*: string
            infLeft*: Expression
            infRight*: Expression
        of IfExpression:
            condition*: Expression
            consequence*: Statement
            alternative*: Option[Statement]
    Expression* = ref ExpressionObject

    StatementObject* = object
        case kind*: StatementKind
        of StLet:
            name*: Expression
            value*: Expression
        of StReturn:
            returnValue*: Expression
        of StExpression:
            expression*: Expression
        of StBlock:
            token*: Token
            statements*: seq[Statement]
    Statement* = ref StatementObject

proc display(self: Expression): string
proc display(self: Statement): string

proc tokenLiteral*(self: Expression): string =
    return ""

proc display(self: Expression): string =
    case self.kind:
    of ExIdentifier:
        return self.idValue
    of ExIntegerLiteral:
        return $self.intValue
    of ExBooleanLiteral:
        return $self.boolValue
    of ExFunctionLiteral:
        result.add(self.token.literal)
        result.add("(")
        result.add(self.parameters.mapIt(it.display()).join(","))
        result.add(")")
        result.add(self.body.display())
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
    of IfExpression:
        result.add("if ")
        result.add(display(self.condition))
        result.add(" ")
        result.add(self.consequence.display())
        if isSome(self.alternative):
            result.add("else ")
            result.add(self.alternative.get.display())


proc tokenLiteral*(self: Statement): string =
    case self.kind:
        of StLet:
            return "let"
        of StReturn:
            return "return"
        of StExpression:
            return self.expression.tokenLiteral()
        of StBlock:
            return self.token.literal

proc display(self: Statement): string =
    case self.kind:
    of StLet:
        result.add(self.tokenLiteral & " ")
        result.add(self.name.display() & " = " & self.value.display())
        result.add(";")
    of StReturn:
        result.add(self.tokenLiteral & " ")
        result.add(self.returnValue.display())
        result.add(";")
    of StExpression:
        result.add(self.expression.display())
    of StBlock:
        for statement in self.statements:
            result.add(statement.display())

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
