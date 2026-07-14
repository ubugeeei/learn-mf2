module MF2.Runtime.Types

import MF2.Decimal
import MF2.Diagnostic
import MF2.Syntax

%default total

||| A value supplied by the host application or produced by a function.
|||
||| Decimal-bearing constructors deliberately use `Decimal`, not `Double`, so
||| MF2 exact-key selection never depends on binary floating-point rounding.
||| Temporal constructors retain their ISO-like source because locale-aware
||| rendering belongs to the injected handler backend.
public export
data Value
  = StringValue String
  | NumberValue Decimal
  | IntegerValue Integer
  | DateValue String
  | TimeValue String
  | DateTimeValue String
  | UnitValue Decimal String
  | CurrencyValue Decimal String
  | FallbackValue String

public export
Eq Value where
  StringValue left == StringValue right = left == right
  NumberValue left == NumberValue right = left == right
  IntegerValue left == IntegerValue right = left == right
  DateValue left == DateValue right = left == right
  TimeValue left == TimeValue right = left == right
  DateTimeValue left == DateTimeValue right = left == right
  UnitValue left leftUnit == UnitValue right rightUnit = left == right && leftUnit == rightUnit
  CurrencyValue left leftCode == CurrencyValue right rightCode = left == right && leftCode == rightCode
  FallbackValue left == FallbackValue right = left == right
  _ == _ = False

||| Direction metadata used by the default bidi strategy.
|||
||| Direction is supplied by a handler and is never guessed from rendered text.
public export
data Direction = LTR | RTL | UnknownDirection

public export
Eq Direction where
  LTR == LTR = True
  RTL == RTL = True
  UnknownDirection == UnknownDirection = True
  _ == _ = False

||| The matching capability carried by a resolved value.
|||
||| The two strings in `NumberSelection` are the exact formatted key and the
||| selection mode (`plural`, `ordinal`, or `exact`).
public export
data Selection
  = NoSelection
  | StringSelection String
  | NumberSelection Decimal String String

||| The result of expression resolution before it becomes an output part.
|||
||| `fallback` requests source-like braces during formatting and disables
||| selection. `isolate` records an explicit or handler-selected bidi policy.
public export
record ResolvedValue where
  constructor MkResolvedValue
  unwrapped : Value
  formatted : String
  selection : Selection
  direction : Direction
  isolate : Bool
  fallback : Bool

||| Resolved function options. Validation has already rejected duplicate names.
public export
Options : Type
Options = List (String, Value)

||| The common success or diagnostic result returned by every handler.
public export
HandlerResult : Type
HandlerResult = Either Diagnostic ResolvedValue

||| Read-only information supplied to default and application handlers.
public export
record FunctionContext where
  constructor MkFunctionContext
  locale : String
  messageDirection : Direction

||| The normalized shape of a built-in function implementation.
|||
||| Keeping this alias explicit makes the dispatch table readable while leaving
||| room for locale-aware built-ins to use `FunctionContext` in the future.
public export
DefaultHandler : Type
DefaultHandler = FunctionContext -> Span -> Maybe Value -> Options -> HandlerResult

||| An application-defined function handler.
|||
||| Applications extend MF2 through this record instead of adding compiler AST
||| constructors. A handler returns all capabilities needed by formatting,
||| selection, and bidi handling, rather than returning only a string.
public export
record FunctionHandler where
  constructor MkFunctionHandler
  run : FunctionContext -> Maybe ResolvedValue -> Options -> HandlerResult

||| A deliberately simple, ordered registry of application handlers.
public export
Registry : Type
Registry = List (Identifier, FunctionHandler)

||| Runtime inputs and formatting policy for one formatting operation.
public export
record Context where
  constructor MkContext
  locale : String
  messageDirection : Direction
  inputs : List (String, Value)
  registry : Registry
  bidiIsolation : Bool

||| Construct an English, LTR context with default bidi isolation enabled.
public export
defaultContext : List (String, Value) -> Context
defaultContext inputs = MkContext "en" LTR inputs [] True

||| One item of structured formatter output.
|||
||| Markup remains inert data and is never serialized as executable markup by
||| the default string formatter.
public export
data OutputPart
  = TextOutput String
  | ExpressionOutput String Direction Bool (List Attribute)
  | MarkupOutput MarkupKind Identifier Options (List Attribute)

||| Structured output paired with every runtime diagnostic observed.
|||
||| A valid message always produces a result. Resolution and handler failures
||| therefore appear alongside specification-defined fallback output.
public export
record FormatResult where
  constructor MkFormatResult
  parts : List OutputPart
  errors : List Diagnostic
