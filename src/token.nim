type TokenType* = enum
  Illegal = "ILLEGAL",
  EOF = "EOF",
  Ident = "IDENT",
  Int = "INT",
  Assign = "=",
  Plus = "+",
  Minus = "-",
  Bang = "!",
  Asterisk = "*",
  Slash = "/",
  Lt = "<",
  Gt = ">",
  Comma = ",",
  SemiColon = ";",
  LParen = "(",
  RParen = ")",
  LBrace = "{",
  RBrace = "}",
  Function = "FUNCTION",
  Let = "LET",
  True = "TRUE",
  False = "FALSE",
  If = "IF",
  Else = "ELSE",
  Return = "RETURN",
  Eq = "==",
  NotEq = "!="


type Token* = object
  kind*: TokenType
  literal*: string


proc lookUpIdent*(ident: string): TokenType =
  case ident:
    of "let":
      return TokenType.Let
    of "fn":
      return TokenType.Function
    of "true":
      return TokenType.True
    of "false":
      return TokenType.False
    of "if":
      return TokenType.If
    of "else":
      return TokenType.Else
    of "return":
      return TokenType.Return
    else:
      return TokenType.Ident
