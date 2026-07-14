module MF2.Runtime.Environment

import MF2.Decimal
import MF2.Diagnostic
import MF2.Runtime.Types
import MF2.Syntax

%default total

||| Values resolved so far, indexed by their MF2 variable names.
export
ResolvedEnv : Type
ResolvedEnv = List (String, ResolvedValue)

||| Look up a resolved variable without exposing the environment representation.
export
lookupResolved : String -> ResolvedEnv -> Maybe ResolvedValue
lookupResolved name [] = Nothing
lookupResolved name ((candidate, value) :: rest) =
  if name == candidate then Just value else lookupResolved name rest

||| Insert or replace one resolved variable.
export
putResolved : String -> ResolvedValue -> ResolvedEnv -> ResolvedEnv
putResolved name value [] = [(name, value)]
putResolved name value ((candidate, existing) :: rest) =
  if name == candidate
     then (name, value) :: rest
     else (candidate, existing) :: putResolved name value rest

||| Render a host value without applying a function or bidi isolation.
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

||| Lift a host value into the resolution protocol without adding selection.
export
rawResolved : Value -> ResolvedValue
rawResolved value@(FallbackValue source) =
  MkResolvedValue value source NoSelection UnknownDirection True True
rawResolved value =
  MkResolvedValue value (rawString value) NoSelection UnknownDirection False False

||| Create the initial environment from application inputs.
export
initialEnvironment : List (String, Value) -> ResolvedEnv
initialEnvironment = map (\(name, value) => (name, rawResolved value))

||| Construct a runtime diagnostic at a known source span.
export
runtimeDiagnostic : ErrorKind -> Span -> String -> Diagnostic
runtimeDiagnostic = MkDiagnostic

escapeFallback : List Char -> List Char
escapeFallback [] = []
escapeFallback ('\\' :: rest) = '\\' :: '\\' :: escapeFallback rest
escapeFallback ('|' :: rest) = '\\' :: '|' :: escapeFallback rest
escapeFallback (char :: rest) = char :: escapeFallback rest

||| Reconstruct the specification-defined source form used by a fallback value.
public export
fallbackSource : Expression -> String
fallbackSource expression = case expression.operand of
  Just (Literal value) => "|" ++ pack (escapeFallback (unpack value)) ++ "|"
  Just (Variable name) => "$" ++ name
  Nothing => case expression.function of
    Just function => ":" ++ show function.name
    Nothing => "�"

||| Turn an expression into an unresolved, source-preserving value.
export
fallbackResolved : Expression -> ResolvedValue
fallbackResolved expression = rawResolved (FallbackValue (fallbackSource expression))

||| Resolve a literal or variable before any function is invoked.
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

||| Resolve option literals and variables while preserving independent errors.
export
resolveOptions : ResolvedEnv -> List Option -> (Options, List Diagnostic)
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

||| Look up one resolved option by name.
export
lookupOption : String -> Options -> Maybe Value
lookupOption name [] = Nothing
lookupOption name ((candidate, value) :: rest) =
  if name == candidate then Just value else lookupOption name rest

||| Read an option as text, using the raw representation of non-string values.
export
stringOption : String -> Options -> Maybe String
stringOption name options = case lookupOption name options of
  Just (StringValue value) => Just value
  Just value => Just (rawString value)
  Nothing => Nothing

||| Coerce the numeric value forms accepted by the reference handlers.
export
asDecimal : Value -> Maybe Decimal
asDecimal (NumberValue value) = Just value
asDecimal (IntegerValue value) = Just (MkDecimal value 0)
asDecimal (StringValue value) = parseDecimal value
asDecimal _ = Nothing

directionFromOptions : Options -> (Direction, Bool)
directionFromOptions options = case stringOption "u:dir" options of
  Just "ltr" => (LTR, True)
  Just "rtl" => (RTL, True)
  Just "auto" => (UnknownDirection, True)
  Just "inherit" => (UnknownDirection, False)
  _ => (UnknownDirection, False)

||| Apply `u:dir` metadata without inspecting the formatted characters.
export
withDirection : Options -> ResolvedValue -> ResolvedValue
withDirection options resolved =
  let (direction, isolate) = directionFromOptions options in
  case direction of
    UnknownDirection => { isolate := isolate } resolved
    _ => { direction := direction, isolate := isolate } resolved
