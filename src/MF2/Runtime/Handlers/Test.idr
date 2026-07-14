module MF2.Runtime.Handlers.Test

import MF2.Decimal
import MF2.Diagnostic
import MF2.Runtime.Handlers
import MF2.Runtime.Types
import MF2.Syntax
import MF2.Testing

%default total

context : FunctionContext
context = MkFunctionContext "en" LTR

span : Span
span = MkSpan 0 0

function : Maybe String -> String -> FunctionRef
function scope name = MkFunctionRef (MkIdentifier scope name) [] span

invoke : Maybe String -> String -> Maybe Value -> Options -> Maybe HandlerResult
invoke scope name operand options = runDefault context (function scope name) operand options

formatsAs : String -> Maybe HandlerResult -> Bool
formatsAs expected (Just (Right value)) = value.formatted == expected
formatsAs expected _ = False

failsWith : ErrorKind -> Maybe HandlerResult -> Bool
failsWith expected (Just (Left diagnostic)) = diagnostic.kind == expected
failsWith expected _ = False

isUnknown : Maybe HandlerResult -> Bool
isUnknown Nothing = True
isUnknown _ = False

selectsString : String -> Maybe HandlerResult -> Bool
selectsString expected (Just (Right value)) = case value.selection of
  StringSelection actual => actual == expected
  _ => False
selectsString expected _ = False

||| Direct dispatch and error-path tests for every stable default handler.
public export
handlerTests : Results
handlerTests = checkAll
  [ ("string formatting", formatsAs "value" (invoke Nothing "string" (Just (StringValue "value")) []))
  , ("string selection", selectsString "value" (invoke Nothing "string" (Just (StringValue "value")) []))
  , ("string requires operand", failsWith BadOperand (invoke Nothing "string" Nothing []))
  , ("string rejects fallback", failsWith BadOperand (invoke Nothing "string" (Just (FallbackValue "$x")) []))
  , ("number parses strings", formatsAs "1.25" (invoke Nothing "number" (Just (StringValue "1.25")) []))
  , ("number rejects text", failsWith BadOperand (invoke Nothing "number" (Just (StringValue "one")) []))
  , ("integer truncates positive", formatsAs "12" (invoke Nothing "integer" (Just (StringValue "12.9")) []))
  , ("integer truncates negative", formatsAs "-12" (invoke Nothing "integer" (Just (StringValue "-12.9")) []))
  , ("offset add", formatsAs "3" (invoke Nothing "offset" (Just (IntegerValue 1)) [("add", IntegerValue 2)]))
  , ("offset subtract", formatsAs "1" (invoke Nothing "offset" (Just (IntegerValue 3)) [("subtract", IntegerValue 2)]))
  , ("offset requires one operation", failsWith BadOption (invoke Nothing "offset" (Just (IntegerValue 1)) []))
  , ("offset rejects two operations", failsWith BadOption (invoke Nothing "offset" (Just (IntegerValue 1)) [("add", IntegerValue 1), ("subtract", IntegerValue 1)]))
  , ("offset rejects large digit size", failsWith BadOption (invoke Nothing "offset" (Just (IntegerValue 1)) [("add", IntegerValue 100)]))
  , ("percent formatting", formatsAs "25%" (invoke Nothing "percent" (Just (StringValue "0.25")) []))
  , ("percent rejects text", failsWith BadOperand (invoke Nothing "percent" (Just (StringValue "quarter")) []))
  , ("currency formatting", formatsAs "USD 12" (invoke Nothing "currency" (Just (IntegerValue 12)) [("currency", StringValue "USD")]))
  , ("currency value retains code", formatsAs "EUR 2" (invoke Nothing "currency" (Just (CurrencyValue (MkDecimal 2 0) "EUR")) []))
  , ("currency requires code", failsWith BadOperand (invoke Nothing "currency" (Just (IntegerValue 12)) []))
  , ("currency validates code", failsWith BadOption (invoke Nothing "currency" (Just (IntegerValue 12)) [("currency", StringValue "US")]))
  , ("unit formatting", formatsAs "12 meter" (invoke Nothing "unit" (Just (IntegerValue 12)) [("unit", StringValue "meter")]))
  , ("unit value retains unit", formatsAs "2 second" (invoke Nothing "unit" (Just (UnitValue (MkDecimal 2 0) "second")) []))
  , ("unit requires name", failsWith BadOperand (invoke Nothing "unit" (Just (IntegerValue 12)) []))
  , ("date preserves source", formatsAs "2026-07-14" (invoke Nothing "date" (Just (StringValue "2026-07-14")) []))
  , ("time preserves source", formatsAs "12:30" (invoke Nothing "time" (Just (TimeValue "12:30")) []))
  , ("datetime preserves source", formatsAs "2026-07-14T12:30" (invoke Nothing "datetime" (Just (DateTimeValue "2026-07-14T12:30")) []))
  , ("temporal rejects number", failsWith BadOperand (invoke Nothing "date" (Just (IntegerValue 1)) []))
  , ("unknown default", isUnknown (invoke Nothing "missing" Nothing []))
  , ("namespaced default is not built in", isUnknown (invoke (Just "app") "number" (Just (IntegerValue 1)) []))
  , ("rtl metadata reaches result", case invoke Nothing "string" (Just (StringValue "text")) [("u:dir", StringValue "rtl")] of
       Just (Right value) => value.direction == RTL && value.isolate
       _ => False)
  ]
