type TokenType* = enum
  Illegal = "ILLEGAL",
  EOF = "EOF",
  Ident = "IDENT",
  Int = "INT",
  Assign = "=",
  Plus = "+",
  Comma = ",",
  SemiColon = ";",
  LParen = "(",
  RParen = ")",
  LBrace = "{",
  RBrace = "}",
  Function = "FUNCTION",
  Let = "LET"


type Token* = object
  kind*: TokenType
  literal*: string
