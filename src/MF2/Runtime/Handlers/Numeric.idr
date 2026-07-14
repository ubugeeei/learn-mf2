module MF2.Runtime.Handlers.Numeric

import MF2.Decimal
import MF2.Diagnostic
import MF2.Runtime.Environment
import MF2.Runtime.Types

%default total

decimalOperand : Span -> String -> String -> Maybe Value -> Either Diagnostic Decimal
decimalOperand span missing invalid Nothing = Left (runtimeDiagnostic BadOperand span missing)
decimalOperand span missing invalid (Just value) = case asDecimal value of
  Nothing => Left (runtimeDiagnostic BadOperand span invalid)
  Just decimal => Right decimal

selectionMode : Options -> String
selectionMode options = case stringOption "select" options of
  Just value => value
  Nothing => "plural"

||| Implement `:number` and `:integer`.
|||
||| The Boolean selects integer mode, whose truncation is toward zero. Both
||| forms retain exact-decimal information for matcher selection.
export
numberHandler : Bool -> DefaultHandler
numberHandler integer _ span operand options = do
  source <- decimalOperand span
    "a numeric function requires an operand"
    "operand does not match the MF2 number-literal production"
    operand
  let decimal = if integer then truncateDecimal source else source
      rendered = renderDecimal decimal
      value = if integer
        then IntegerValue (case wholeValue decimal of Just whole => whole; Nothing => 0)
        else NumberValue decimal
      resolved = MkResolvedValue value rendered
                   (NumberSelection decimal rendered (selectionMode options))
                   LTR False False
  Right (withDirection options resolved)

digitSize : Value -> Maybe Integer
digitSize value = case asDecimal value of
  Just decimal => case wholeValue decimal of
    Just integer => if integer >= 0 && integer <= 99 then Just integer else Nothing
    Nothing => Nothing
  Nothing => Nothing

digitOption : Span -> String -> Value -> Either Diagnostic Integer
digitOption span name value = case digitSize value of
  Just amount => Right amount
  Nothing => Left (runtimeDiagnostic BadOption span
             ("`" ++ name ++ "` must be a digit-size option"))

offsetAmount : Span -> Options -> Either Diagnostic Integer
offsetAmount span options = case (lookupOption "add" options, lookupOption "subtract" options) of
  (Just value, Nothing) => digitOption span "add" value
  (Nothing, Just value) => map negate (digitOption span "subtract" value)
  _ => Left (runtimeDiagnostic BadOption span
       ":offset requires exactly one of `add` or `subtract`")

||| Implement `:offset` with exact integer addition or subtraction.
export
offsetHandler : DefaultHandler
offsetHandler _ span operand options = do
  decimal <- decimalOperand span
    ":offset requires a numeric operand"
    ":offset requires a numeric operand"
    operand
  amount <- offsetAmount span options
  let result = addWhole decimal amount
      rendered = renderDecimal result
      resolved = MkResolvedValue (NumberValue result) rendered
                   (NumberSelection result rendered "plural") LTR False False
  Right (withDirection options resolved)

||| Implement `:percent` using exact multiplication by one hundred.
export
percentHandler : DefaultHandler
percentHandler _ span operand options = do
  decimal <- decimalOperand span
    ":percent requires a numeric operand"
    ":percent requires a numeric operand"
    operand
  let rendered = renderDecimal (multiplyWhole decimal 100) ++ "%"
      exact = renderDecimal decimal
      resolved = MkResolvedValue (NumberValue decimal) rendered
                   (NumberSelection decimal exact (selectionMode options))
                   LTR False False
  Right (withDirection options resolved)
