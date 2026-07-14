module MF2.Runtime

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

ResolvedEnv : Type
ResolvedEnv = List (String, ResolvedValue)

lookupResolved : String -> ResolvedEnv -> Maybe ResolvedValue
lookupResolved name [] = Nothing
lookupResolved name ((candidate, value) :: rest) =
  if name == candidate then Just value else lookupResolved name rest

putResolved : String -> ResolvedValue -> ResolvedEnv -> ResolvedEnv
putResolved name value [] = [(name, value)]
putResolved name value ((candidate, existing) :: rest) =
  if name == candidate
     then (name, value) :: rest
     else (candidate, existing) :: putResolved name value rest

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

rawResolved : Value -> ResolvedValue
rawResolved value@(FallbackValue source) =
  MkResolvedValue value source NoSelection UnknownDirection True True
rawResolved value =
  MkResolvedValue value (rawString value) NoSelection UnknownDirection False False

initialEnvironment : List (String, Value) -> ResolvedEnv
initialEnvironment = map (\(name, value) => (name, rawResolved value))

runtimeDiagnostic : ErrorKind -> Span -> String -> Diagnostic
runtimeDiagnostic = MkDiagnostic

escapeFallback : List Char -> List Char
escapeFallback [] = []
escapeFallback ('\\' :: rest) = '\\' :: '\\' :: escapeFallback rest
escapeFallback ('|' :: rest) = '\\' :: '|' :: escapeFallback rest
escapeFallback (char :: rest) = char :: escapeFallback rest

fallbackSource : Expression -> String
fallbackSource expression = case expression.operand of
  Just (Literal value) => "|" ++ pack (escapeFallback (unpack value)) ++ "|"
  Just (Variable name) => "$" ++ name
  Nothing => case expression.function of
    Just function => ":" ++ show function.name
    Nothing => "�"

fallbackResolved : Expression -> ResolvedValue
fallbackResolved expression =
  rawResolved (FallbackValue (fallbackSource expression))

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

lookupOption : String -> List (String, Value) -> Maybe Value
lookupOption name [] = Nothing
lookupOption name ((candidate, value) :: rest) =
  if name == candidate then Just value else lookupOption name rest

stringOption : String -> List (String, Value) -> Maybe String
stringOption name options = case lookupOption name options of
  Just (StringValue value) => Just value
  Just value => Just (rawString value)
  Nothing => Nothing

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

withDirection : List (String, Value) -> ResolvedValue -> ResolvedValue
withDirection options resolved =
  let (direction, isolate) = directionFromOptions options in
  case direction of
    UnknownDirection => { isolate := isolate } resolved
    _ => { direction := direction, isolate := isolate } resolved

stringHandler : Span -> Maybe Value -> List (String, Value)
             -> Either Diagnostic ResolvedValue
stringHandler span Nothing options =
  Left (runtimeDiagnostic BadOperand span ":string requires an operand")
stringHandler span (Just (FallbackValue _)) options =
  Left (runtimeDiagnostic BadOperand span ":string received a fallback operand")
stringHandler span (Just value) options =
  let rendered = rawString value in
  Right (withDirection options
    (MkResolvedValue (StringValue rendered) rendered
      (StringSelection rendered) UnknownDirection False False))

numberHandler : Bool -> Span -> Maybe Value -> List (String, Value)
             -> Either Diagnostic ResolvedValue
numberHandler integer span Nothing options =
  Left (runtimeDiagnostic BadOperand span "a numeric function requires an operand")
numberHandler integer span (Just value) options = case asDecimal value of
  Nothing => Left (runtimeDiagnostic BadOperand span
                    "operand does not match the MF2 number-literal production")
  Just decimal =>
    let decimal = if integer then truncateDecimal decimal else decimal
        select = case stringOption "select" options of
          Just value => value
          Nothing => "plural"
        value = if integer
                   then IntegerValue (case wholeValue decimal of
                     Just value => value
                     Nothing => 0)
                   else NumberValue decimal in
    Right (withDirection options
      (MkResolvedValue value (renderDecimal decimal)
        (NumberSelection decimal (renderDecimal decimal) select) LTR False False))

digitSize : Value -> Maybe Integer
digitSize value = case asDecimal value of
  Just decimal => case wholeValue decimal of
    Just integer => if integer >= 0 && integer <= 99 then Just integer else Nothing
    Nothing => Nothing
  Nothing => Nothing

offsetHandler : Span -> Maybe Value -> List (String, Value)
             -> Either Diagnostic ResolvedValue
offsetHandler span Nothing options =
  Left (runtimeDiagnostic BadOperand span ":offset requires a numeric operand")
offsetHandler span (Just value) options = case asDecimal value of
  Nothing => Left (runtimeDiagnostic BadOperand span ":offset requires a numeric operand")
  Just decimal => case (lookupOption "add" options, lookupOption "subtract" options) of
    (Just amount, Nothing) => case digitSize amount of
      Nothing => Left (runtimeDiagnostic BadOption span "`add` must be a digit-size option")
      Just amount => numberResult (addWhole decimal amount)
    (Nothing, Just amount) => case digitSize amount of
      Nothing => Left (runtimeDiagnostic BadOption span "`subtract` must be a digit-size option")
      Just amount => numberResult (addWhole decimal (negate amount))
    _ => Left (runtimeDiagnostic BadOption span
               ":offset requires exactly one of `add` or `subtract`")
  where
    numberResult : Decimal -> Either Diagnostic ResolvedValue
    numberResult decimal = Right (withDirection options
      (MkResolvedValue (NumberValue decimal) (renderDecimal decimal)
        (NumberSelection decimal (renderDecimal decimal) "plural") LTR False False))

percentHandler : Span -> Maybe Value -> List (String, Value)
              -> Either Diagnostic ResolvedValue
percentHandler span Nothing options =
  Left (runtimeDiagnostic BadOperand span ":percent requires a numeric operand")
percentHandler span (Just value) options = case asDecimal value of
  Nothing => Left (runtimeDiagnostic BadOperand span ":percent requires a numeric operand")
  Just decimal =>
    let renderedValue = multiplyWhole decimal 100
        select = case stringOption "select" options of
          Just value => value
          Nothing => "plural" in
    Right (withDirection options
      (MkResolvedValue (NumberValue decimal) (renderDecimal renderedValue ++ "%")
        (NumberSelection decimal (renderDecimal decimal) select) LTR False False))

currencyHandler : Span -> Maybe Value -> List (String, Value)
               -> Either Diagnostic ResolvedValue
currencyHandler span Nothing options =
  Left (runtimeDiagnostic BadOperand span ":currency requires an operand")
currencyHandler span (Just value) options = case asDecimal value of
  Nothing => case value of
    CurrencyValue decimal code => result decimal code
    _ => Left (runtimeDiagnostic BadOperand span ":currency requires a numeric or currency operand")
  Just decimal => case stringOption "currency" options of
    Nothing => Left (runtimeDiagnostic BadOperand span
                     "a numeric :currency operand requires the `currency` option")
    Just code => if length (unpack code) == 3 && all isAlpha (unpack code)
                    then result decimal code
                    else Left (runtimeDiagnostic BadOption span
                               "currency must be a three-letter identifier")
  where
    result : Decimal -> String -> Either Diagnostic ResolvedValue
    result decimal code = Right (withDirection options
      (MkResolvedValue (CurrencyValue decimal code)
        (code ++ " " ++ renderDecimal decimal) NoSelection LTR False False))

unitHandler : Span -> Maybe Value -> List (String, Value)
           -> Either Diagnostic ResolvedValue
unitHandler span Nothing options =
  Left (runtimeDiagnostic BadOperand span ":unit requires an operand")
unitHandler span (Just value) options = case value of
  UnitValue decimal unit => result decimal unit
  _ => case asDecimal value of
    Nothing => Left (runtimeDiagnostic BadOperand span ":unit requires a numeric or unit operand")
    Just decimal => case stringOption "unit" options of
      Nothing => Left (runtimeDiagnostic BadOperand span
                       "a numeric :unit operand requires the `unit` option")
      Just unit => result decimal unit
  where
    result : Decimal -> String -> Either Diagnostic ResolvedValue
    result decimal unit = Right (withDirection options
      (MkResolvedValue (UnitValue decimal unit)
        (renderDecimal decimal ++ " " ++ unit) NoSelection LTR False False))

temporalHandler : String -> Span -> Maybe Value -> List (String, Value)
               -> Either Diagnostic ResolvedValue
temporalHandler kind span Nothing options =
  Left (runtimeDiagnostic BadOperand span (":" ++ kind ++ " requires an operand"))
temporalHandler kind span (Just value) options = case value of
  StringValue source => result source
  DateValue source => result source
  TimeValue source => result source
  DateTimeValue source => result source
  _ => Left (runtimeDiagnostic BadOperand span
             (":" ++ kind ++ " requires a temporal or string operand"))
  where
    result : String -> Either Diagnostic ResolvedValue
    result source =
      let value = case kind of
            "date" => DateValue source
            "time" => TimeValue source
            _ => DateTimeValue source in
      Right (withDirection options
        (MkResolvedValue value source NoSelection LTR False False))

findCustom : Identifier -> Registry -> Maybe FunctionHandler
findCustom identifier [] = Nothing
findCustom identifier ((candidate, handler) :: rest) =
  if identifier == candidate then Just handler else findCustom identifier rest

runDefault : FunctionContext -> FunctionRef -> Maybe Value
          -> List (String, Value) -> Maybe (Either Diagnostic ResolvedValue)
runDefault context function operand options = case (function.name.scope, function.name.name) of
  (Nothing, "string") => Just (stringHandler function.span operand options)
  (Nothing, "number") => Just (numberHandler False function.span operand options)
  (Nothing, "integer") => Just (numberHandler True function.span operand options)
  (Nothing, "offset") => Just (offsetHandler function.span operand options)
  (Nothing, "percent") => Just (percentHandler function.span operand options)
  (Nothing, "currency") => Just (currencyHandler function.span operand options)
  (Nothing, "unit") => Just (unitHandler function.span operand options)
  (Nothing, "datetime") => Just (temporalHandler "datetime" function.span operand options)
  (Nothing, "date") => Just (temporalHandler "date" function.span operand options)
  (Nothing, "time") => Just (temporalHandler "time" function.span operand options)
  _ => Nothing

resolveExpression : Context -> ResolvedEnv -> Expression
                 -> (ResolvedValue, List Diagnostic)
resolveExpression context environment expression =
  let (operand, operandErrors) = case expression.operand of
        Nothing => (Nothing, the (List Diagnostic) [])
        Just source => let (resolved, errors) = resolveOperand environment source
                        in (Just resolved, errors) in
  case expression.function of
    Nothing => case operand of
      Just resolved => (resolved, operandErrors)
      Nothing => (fallbackResolved expression,
                  runtimeDiagnostic BadOperand expression.span
                    "an expression must contain an operand or function" :: operandErrors)
    Just function => case operand of
      Just resolved => if resolved.fallback
        then (fallbackResolved expression, operandErrors)
        else invoke function (Just resolved) operandErrors
      Nothing => invoke function Nothing operandErrors
  where
    invoke : FunctionRef -> Maybe ResolvedValue -> List Diagnostic
          -> (ResolvedValue, List Diagnostic)
    invoke function operand earlierErrors =
      let (options, optionErrors) = resolveOptions environment function.options
          functionContext = MkFunctionContext context.locale context.messageDirection
          result = case findCustom function.name context.registry of
            Just handler => Just (handler.run functionContext operand options)
            Nothing => runDefault functionContext function (map (.unwrapped) operand) options in
      case result of
        Nothing => (fallbackResolved expression,
          earlierErrors ++ optionErrors ++
          [runtimeDiagnostic UnknownFunction function.span
            ("no handler is registered for `:" ++ show function.name ++ "`")])
        Just (Left error) => (fallbackResolved expression,
                              earlierErrors ++ optionErrors ++ [error])
        Just (Right value) => (value, earlierErrors ++ optionErrors)

evaluateDeclarations : Context -> ResolvedEnv -> List Declaration
                    -> (ResolvedEnv, List Diagnostic)
evaluateDeclarations context environment [] = (environment, [])
evaluateDeclarations context environment (declaration :: rest) =
  let name = declaredName declaration
      expression = declarationExpression declaration
      (resolved, errors) = resolveExpression context environment expression
      nextEnvironment = putResolved name resolved environment
      (finalEnvironment, laterErrors) =
        evaluateDeclarations context nextEnvironment rest in
      (finalEnvironment, errors ++ laterErrors)

localePrefix : String -> String
localePrefix locale = pack (takeUntilDash (unpack locale))
  where
    takeUntilDash : List Char -> List Char
    takeUntilDash [] = []
    takeUntilDash ('-' :: rest) = []
    takeUntilDash (char :: rest) = char :: takeUntilDash rest

pluralKeyword : String -> String -> Decimal -> String
pluralKeyword locale "exact" decimal = ""
pluralKeyword locale "ordinal" decimal = case wholeValue decimal of
  Nothing => "other"
  Just value => if localePrefix locale == "en"
    then let mod10 = abs value `mod` 10
             mod100 = abs value `mod` 100 in
         if mod10 == 1 && mod100 /= 11 then "one"
         else if mod10 == 2 && mod100 /= 12 then "two"
         else if mod10 == 3 && mod100 /= 13 then "few"
         else "other"
    else "other"
pluralKeyword locale mode decimal = case localePrefix locale of
  "ja" => "other"
  "zh" => "other"
  "ko" => "other"
  "fr" => case wholeValue decimal of
    Just 0 => "one"
    Just 1 => "one"
    _ => "other"
  "en" => case wholeValue decimal of
    Just 1 => "one"
    _ => "other"
  _ => case wholeValue decimal of
    Just 1 => "one"
    _ => "other"

selectionScore : String -> ResolvedValue -> Key -> Int
selectionScore locale resolved Catchall = 0
selectionScore locale resolved (LiteralKey key) = case resolved.selection of
  NoSelection => -1
  StringSelection value => if value == key then 2 else -1
  NumberSelection decimal exact mode => case parseDecimal key of
    Just keyValue => if exact == key then 2 else -1
    Nothing => if pluralKeyword locale mode decimal == key then 1 else -1

scores : String -> List ResolvedValue -> List Key -> List Int
scores locale [] [] = []
scores locale (selector :: selectors) (key :: keys) =
  selectionScore locale selector key :: scores locale selectors keys
scores locale _ _ = []

allMatched : List Int -> Bool
allMatched [] = True
allMatched (score :: rest) = score >= 0 && allMatched rest

betterScores : List Int -> List Int -> Bool
betterScores [] [] = False
betterScores (left :: lefts) (right :: rights) =
  if left > right then True
  else if left < right then False
  else betterScores lefts rights
betterScores _ _ = False

selectBest : String -> List ResolvedValue -> Variant arity
          -> List (Variant arity) -> Variant arity
selectBest locale selectors best [] = best
selectBest locale selectors best (candidate :: rest) =
  let candidateScores = scores locale selectors (toList candidate.keys)
      bestScores = scores locale selectors (toList best.keys)
      next = if allMatched candidateScores && betterScores candidateScores bestScores
                then candidate else best in
      selectBest locale selectors next rest

fallbackVariant : FallbackVariant arity -> Variant arity
fallbackVariant fallback = MkVariant fallback.keys fallback.value

resolveSelectors : ResolvedEnv -> List Selector
                -> (List ResolvedValue, List Diagnostic)
resolveSelectors environment [] = ([], [])
resolveSelectors environment (selector :: rest) =
  let (more, laterErrors) = resolveSelectors environment rest in
  case lookupResolved selector.variable environment of
    Just value => case value.selection of
      NoSelection => (rawResolved (FallbackValue ("$" ++ selector.variable)) :: more,
        point BadSelector 0 ("`$" ++ selector.variable ++ "` does not support selection") :: laterErrors)
      _ => (value :: more, laterErrors)
    Nothing => (rawResolved (FallbackValue ("$" ++ selector.variable)) :: more,
      point BadSelector 0 ("`$" ++ selector.variable ++ "` is unresolved") :: laterErrors)

selectPattern : Context -> ResolvedEnv -> MatchPlan planTail
             -> (Pattern, List Diagnostic)
selectPattern context environment plan =
  let (selectors, errors) = resolveSelectors environment (toList plan.selectors)
      best = selectBest context.locale selectors (fallbackVariant plan.fallback) plan.variants in
      (best.value, errors)

||| A structured output part. Markup remains data and is never serialized as
||| executable markup by the default string formatter.
public export
data OutputPart
  = TextOutput String
  | ExpressionOutput String Direction Bool (List Attribute)
  | MarkupOutput MarkupKind Identifier (List (String, Value)) (List Attribute)

||| The formatter returns both usable output and every runtime diagnostic it
||| observed. A valid message therefore always yields a result, even when a
||| variable or handler fails and a spec-defined fallback is inserted.
public export
record FormatResult where
  constructor MkFormatResult
  parts : List OutputPart
  errors : List Diagnostic

formatPart : Context -> ResolvedEnv -> PatternPart
          -> (OutputPart, List Diagnostic)
formatPart context environment (Text value) = (TextOutput value, [])
formatPart context environment (Place expression) =
  let (resolved, errors) = resolveExpression context environment expression
      rendered = if resolved.fallback
                    then "{" ++ resolved.formatted ++ "}"
                    else resolved.formatted in
      (ExpressionOutput rendered resolved.direction resolved.isolate expression.attributes, errors)
formatPart context environment (Mark markup) =
  let (options, errors) = resolveOptions environment markup.options in
      (MarkupOutput markup.kind markup.name options markup.attributes, errors)

formatPattern : Context -> ResolvedEnv -> Pattern -> FormatResult
formatPattern context environment [] = MkFormatResult [] []
formatPattern context environment (part :: rest) =
  let (output, errors) = formatPart context environment part
      later = formatPattern context environment rest in
      MkFormatResult (output :: later.parts) (errors ++ later.errors)

||| Resolve declarations exactly once, select a variant using the arity-safe
||| plan, and produce structured parts suitable for rich-text renderers.
public export
formatToParts : Context -> CompiledMessage -> FormatResult
formatToParts context message =
  let initial = initialEnvironment context.inputs
      (environment, declarationErrors) =
        evaluateDeclarations context initial message.declarations
      (pattern, selectionErrors) = case message.body of
        Static pattern => (pattern, the (List Diagnostic) [])
        Dynamic planTail plan => selectPattern context environment plan
      result = formatPattern context environment pattern in
      MkFormatResult result.parts
        (declarationErrors ++ selectionErrors ++ result.errors)

isolateText : Direction -> Direction -> Bool -> String -> String
isolateText messageDirection LTR requested value =
  if messageDirection == LTR && not requested
     then value else "⁦" ++ value ++ "⁩"
isolateText messageDirection RTL requested value = "⁧" ++ value ++ "⁩"
isolateText messageDirection UnknownDirection requested value = "⁨" ++ value ++ "⁩"

renderPart : Context -> OutputPart -> String
renderPart context (TextOutput value) = value
renderPart context (MarkupOutput _ _ _ _) = ""
renderPart context (ExpressionOutput value direction isolate _) =
  if context.bidiIsolation
     then isolateText context.messageDirection direction isolate value
     else value

||| Render structured parts as a string. Markup becomes empty and the default
||| bidi isolation algorithm wraps expression output when required.
public export
formatToString : Context -> CompiledMessage -> (String, List Diagnostic)
formatToString context message =
  let result = formatToParts context message in
      (concat (map (renderPart context) result.parts), result.errors)
