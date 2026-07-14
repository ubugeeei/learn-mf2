module MF2.Runtime.Types

import Data.Vect
import MF2.Decimal
import MF2.Diagnostic
import MF2.IR
import MF2.Syntax

%default total

||| Runtime values supported by the reference implementation. Decimal values
||| remain arbitrary precision; temporal values retain their ISO-like source
||| representation because locale data is intentionally supplied by handlers.
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

||| Direction metadata is carried separately from rendered text, as required
||| by the default bidi strategy. It is never guessed from output characters.
public export
data Direction = LTR | RTL | UnknownDirection

public export
Eq Direction where
  LTR == LTR = True
  RTL == RTL = True
  UnknownDirection == UnknownDirection = True
  _ == _ = False

||| The operations a resolved value provides to pattern selection.
public export
data Selection
  = NoSelection
  | StringSelection String
  | NumberSelection Decimal String String

||| The result of resolving one expression. `fallback` changes string
||| formatting by adding braces and disables selection.
public export
record ResolvedValue where
  constructor MkResolvedValue
  unwrapped : Value
  formatted : String
  selection : Selection
  direction : Direction
  isolate : Bool
  fallback : Bool

||| Read-only information supplied to function handlers.
public export
record FunctionContext where
  constructor MkFunctionContext
  locale : String
  messageDirection : Direction

||| A custom function handler. Applications can extend MF2 without extending
||| the compiler AST, while still returning the exact capabilities needed by
||| formatting and selection.
public export
record FunctionHandler where
  constructor MkFunctionHandler
  run : FunctionContext -> Maybe ResolvedValue -> List (String, Value)
     -> Either Diagnostic ResolvedValue

public export
Registry : Type
Registry = List (Identifier, FunctionHandler)

||| Formatting policy and runtime inputs. The default context enables LDML's
||| required plain-string bidi isolation strategy.
public export
record Context where
  constructor MkContext
  locale : String
  messageDirection : Direction
  inputs : List (String, Value)
  registry : Registry
  bidiIsolation : Bool

||| The recommended starter context for an LTR application.
public export
defaultContext : List (String, Value) -> Context
defaultContext inputs = MkContext "en" LTR inputs [] True

export
ResolvedEnv : Type
ResolvedEnv = List (String, ResolvedValue)

export
lookupResolved : String -> ResolvedEnv -> Maybe ResolvedValue
lookupResolved name [] = Nothing
lookupResolved name ((candidate, value) :: rest) =
  if name == candidate then Just value else lookupResolved name rest

export
putResolved : String -> ResolvedValue -> ResolvedEnv -> ResolvedEnv
putResolved name value [] = [(name, value)]
putResolved name value ((candidate, existing) :: rest) =
  if name == candidate
     then (name, value) :: rest
     else (candidate, existing) :: putResolved name value rest

export
rawString : Value -> String
rawString (StringValue value) = value
rawString (NumberValue value) = renderDecimal value
rawString (IntegerValue value) = show value
rawString (DateValue value) = value
rawString (TimeValue value) = value
rawString (DateTimeValue value) = value
rawString (UnitValue value unit) = renderDecimal value ++ " " ++ unit
rawString (CurrencyValue value currency) = currency ++ " " ++ renderDecimal value
rawString (FallbackValue value) = value

export
rawResolved : Value -> ResolvedValue
rawResolved value@(FallbackValue source) =
  MkResolvedValue value source NoSelection UnknownDirection True True
rawResolved value =
  MkResolvedValue value (rawString value) NoSelection UnknownDirection False False

export
initialEnvironment : List (String, Value) -> ResolvedEnv
initialEnvironment = map (\(name, value) => (name, rawResolved value))

export
runtimeDiagnostic : ErrorKind -> Span -> String -> Diagnostic
runtimeDiagnostic = MkDiagnostic

escapeFallback : List Char -> List Char
escapeFallback [] = []
escapeFallback ('\\' :: rest) = '\\' :: '\\' :: escapeFallback rest
escapeFallback ('|' :: rest) = '\\' :: '|' :: escapeFallback rest
escapeFallback (char :: rest) = char :: escapeFallback rest

export
fallbackSource : Expression -> String
fallbackSource expression = case expression.operand of
  Just (Literal value) => "|" ++ pack (escapeFallback (unpack value)) ++ "|"
  Just (Variable name) => "$" ++ name
  Nothing => case expression.function of
    Just function => ":" ++ show function.name
    Nothing => "�"

export
fallbackResolved : Expression -> ResolvedValue
fallbackResolved expression =
  rawResolved (FallbackValue (fallbackSource expression))

export
resolveOperand : ResolvedEnv -> Operand -> (ResolvedValue, List Diagnostic)
resolveOperand environment (Literal value) = (rawResolved (StringValue value), [])
resolveOperand environment (Variable name) = case lookupResolved name environment of
  Just value => if value.fallback
    then (rawResolved (FallbackValue ("$" ++ name)), [])
    else (value, [])
  Nothing => (rawResolved (FallbackValue ("$" ++ name)),
              [point UnresolvedVariable 0 ("no input or local value for `$" ++ name ++ "`")])

optionName : Option -> String
optionName option = show option.name

export
resolveOptions : ResolvedEnv -> List Option -> (List (String, Value), List Diagnostic)
resolveOptions environment [] = ([], [])
resolveOptions environment (option :: rest) =
  let (more, laterErrors) = resolveOptions environment rest in
  case option.value of
    Literal value => ((optionName option, StringValue value) :: more, laterErrors)
    Variable name => case lookupResolved name environment of
      Just resolved => case resolved.unwrapped of
        FallbackValue _ =>
          (more, runtimeDiagnostic BadOption option.span
             ("option variable `$" ++ name ++ "` is unresolved") :: laterErrors)
        value => ((optionName option, value) :: more, laterErrors)
      Nothing => (more, runtimeDiagnostic BadOption option.span
                   ("option variable `$" ++ name ++ "` is unresolved") :: laterErrors)

export
lookupOption : String -> List (String, Value) -> Maybe Value
lookupOption name [] = Nothing
lookupOption name ((candidate, value) :: rest) =
  if name == candidate then Just value else lookupOption name rest

export
stringOption : String -> List (String, Value) -> Maybe String
stringOption name options = case lookupOption name options of
  Just (StringValue value) => Just value
  Just value => Just (rawString value)
  Nothing => Nothing

export
asDecimal : Value -> Maybe Decimal
asDecimal (NumberValue value) = Just value
asDecimal (IntegerValue value) = Just (MkDecimal value 0)
asDecimal (StringValue value) = parseDecimal value
asDecimal _ = Nothing

directionFromOptions : List (String, Value) -> (Direction, Bool)
directionFromOptions options = case stringOption "u:dir" options of
  Just "ltr" => (LTR, True)
  Just "rtl" => (RTL, True)
  Just "auto" => (UnknownDirection, True)
  Just "inherit" => (UnknownDirection, False)
  _ => (UnknownDirection, False)

export
withDirection : List (String, Value) -> ResolvedValue -> ResolvedValue
withDirection options resolved =
  let (direction, isolate) = directionFromOptions options in
  case direction of
    UnknownDirection => { isolate := isolate } resolved
    _ => { direction := direction, isolate := isolate } resolved
