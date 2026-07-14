module MF2.Runtime.Handlers.Measure

import MF2.Decimal
import MF2.Diagnostic
import MF2.Runtime.Environment
import MF2.Runtime.Types

%default total

validCurrencyCode : String -> Bool
validCurrencyCode code = length (unpack code) == 3 && all isAlpha (unpack code)

currencyInput : Span -> Maybe Value -> Options -> Either Diagnostic (Decimal, String)
currencyInput span Nothing _ =
  Left (runtimeDiagnostic BadOperand span ":currency requires an operand")
currencyInput span (Just (CurrencyValue decimal code)) _ = Right (decimal, code)
currencyInput span (Just value) options = case asDecimal value of
  Nothing => Left (runtimeDiagnostic BadOperand span
             ":currency requires a numeric or currency operand")
  Just decimal => case stringOption "currency" options of
    Nothing => Left (runtimeDiagnostic BadOperand span
               "a numeric :currency operand requires the `currency` option")
    Just code => if validCurrencyCode code
      then Right (decimal, code)
      else Left (runtimeDiagnostic BadOption span
             "currency must be a three-letter identifier")

||| Implement the locale-neutral reference form of `:currency`.
|||
||| Production symbol and pattern selection is intentionally delegated to a
||| locale backend; this handler preserves the exact amount and currency code.
export
currencyHandler : DefaultHandler
currencyHandler _ span operand options = do
  (decimal, code) <- currencyInput span operand options
  let rendered = code ++ " " ++ renderDecimal decimal
  Right (withDirection options
    (MkResolvedValue (CurrencyValue decimal code) rendered NoSelection LTR False False))

unitInput : Span -> Maybe Value -> Options -> Either Diagnostic (Decimal, String)
unitInput span Nothing _ =
  Left (runtimeDiagnostic BadOperand span ":unit requires an operand")
unitInput span (Just (UnitValue decimal unit)) _ = Right (decimal, unit)
unitInput span (Just value) options = case asDecimal value of
  Nothing => Left (runtimeDiagnostic BadOperand span
             ":unit requires a numeric or unit operand")
  Just decimal => case stringOption "unit" options of
    Nothing => Left (runtimeDiagnostic BadOperand span
               "a numeric :unit operand requires the `unit` option")
    Just unit => Right (decimal, unit)

||| Implement the locale-neutral reference form of the draft `:unit` function.
export
unitHandler : DefaultHandler
unitHandler _ span operand options = do
  (decimal, unit) <- unitInput span operand options
  let rendered = renderDecimal decimal ++ " " ++ unit
  Right (withDirection options
    (MkResolvedValue (UnitValue decimal unit) rendered NoSelection LTR False False))
