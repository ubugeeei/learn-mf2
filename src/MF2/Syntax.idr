module MF2.Syntax

import MF2.Diagnostic

%default total

||| An MF2 identifier, retaining an optional namespace separately so the
||| compiler can distinguish Unicode-reserved and application namespaces.
public export
record Identifier where
  constructor MkIdentifier
  scope : Maybe String
  name : String

public export
Eq Identifier where
  left == right = left.scope == right.scope && left.name == right.name

public export
Show Identifier where
  show identifier = case identifier.scope of
    Nothing => identifier.name
    Just scope => scope ++ ":" ++ identifier.name

||| An expression or option operand. The parser normalizes quoted and
||| unquoted literals to their code-point value, as required for key equality.
public export
data Operand = Literal String | Variable String

public export
Eq Operand where
  Literal left == Literal right = left == right
  Variable left == Variable right = left == right
  _ == _ = False

public export
Show Operand where
  show (Literal value) = "|" ++ value ++ "|"
  show (Variable name) = "$" ++ name

||| A named option supplied to a function or markup placeholder.
public export
record Option where
  constructor MkOption
  name : Identifier
  value : Operand
  span : Span

||| A function annotation and its syntactically ordered options.
public export
record FunctionRef where
  constructor MkFunctionRef
  name : Identifier
  options : List Option
  span : Span

||| Metadata attached to expressions and markup. Attribute values are always
||| literals in the stable MF2 grammar.
public export
record Attribute where
  constructor MkAttribute
  name : Identifier
  value : Maybe String
  span : Span

||| The complete expression data model before semantic validation.
public export
record Expression where
  constructor MkExpression
  operand : Maybe Operand
  function : Maybe FunctionRef
  attributes : List Attribute
  span : Span

||| Markup kind is intentionally non-hierarchical: MF2 does not require open
||| and close placeholders to balance or nest like XML.
public export
data MarkupKind = Open | Standalone | Close

public export
Eq MarkupKind where
  Open == Open = True
  Standalone == Standalone = True
  Close == Close = True
  _ == _ = False

||| A safe, semantic markup placeholder. Applications decide what its name
||| means; the compiler never turns it into executable HTML.
public export
record Markup where
  constructor MkMarkup
  kind : MarkupKind
  name : Identifier
  options : List Option
  attributes : List Attribute
  span : Span

||| A pattern is a sequence rather than a string. Keeping expressions and
||| markup structured is what makes rich-text output safe.
public export
data PatternPart = Text String | Place Expression | Mark Markup

public export
Pattern : Type
Pattern = List PatternPart

||| Input declarations may annotate an external variable; local declarations
||| bind the call-by-need result of an expression.
public export
data Declaration
  = InputDeclaration String Expression Span
  | LocalDeclaration String Expression Span

||| Return the variable bound by a declaration.
public export
declaredName : Declaration -> String
declaredName (InputDeclaration name _ _) = name
declaredName (LocalDeclaration name _ _) = name

||| Return the declaration's expression.
public export
declarationExpression : Declaration -> Expression
declarationExpression (InputDeclaration _ expression _) = expression
declarationExpression (LocalDeclaration _ expression _) = expression

||| A catch-all key is structurally different from the literal `|*|`.
public export
data Key = Catchall | LiteralKey String

public export
Eq Key where
  Catchall == Catchall = True
  LiteralKey left == LiteralKey right = left == right
  _ == _ = False

public export
Show Key where
  show Catchall = "*"
  show (LiteralKey value) = "|" ++ value ++ "|"

||| A raw variant can temporarily have any key count. Validation is the only
||| operation that can turn it into the arity-indexed representation.
public export
record RawVariant where
  constructor MkRawVariant
  keys : List Key
  value : Pattern
  span : Span

||| A parsed body. Selectors are names because the surface grammar restricts
||| `.match` to variable references.
public export
data RawBody
  = PatternBody Pattern
  | SelectBody (List String) (List RawVariant)

||| The lossless-enough syntax tree accepted from an untrusted source string.
||| It may be well-formed while still violating data-model constraints.
public export
record RawMessage where
  constructor MkRawMessage
  declarations : List Declaration
  body : RawBody
