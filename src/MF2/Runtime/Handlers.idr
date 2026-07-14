module MF2.Runtime.Handlers

import MF2.Decimal
import MF2.Diagnostic
import MF2.Runtime.Types
import MF2.Syntax

%default total

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

export
findCustom : Identifier -> Registry -> Maybe FunctionHandler
findCustom identifier [] = Nothing
findCustom identifier ((candidate, handler) :: rest) =
  if identifier == candidate then Just handler else findCustom identifier rest

public export
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
