module MF2.Runtime.Environment.Test

import MF2.Decimal
import MF2.Diagnostic
import MF2.Runtime.Environment
import MF2.Runtime.Types
import MF2.Syntax
import MF2.Testing

%default total

span : Span
span = MkSpan 0 0

variableExpression : String -> Expression
variableExpression name = MkExpression (Just (Variable name)) Nothing [] span

literalExpression : String -> Expression
literalExpression value = MkExpression (Just (Literal value)) Nothing [] span

functionExpression : String -> Expression
functionExpression name = MkExpression Nothing
  (Just (MkFunctionRef (MkIdentifier Nothing name) [] span)) [] span

rightDirection : Direction -> Bool -> ResolvedValue -> Bool
rightDirection expected expectedIsolation resolved =
  resolved.direction == expected && resolved.isolate == expectedIsolation

isMissing : {0 valueType : Type} -> Maybe valueType -> Bool
isMissing Nothing = True
isMissing _ = False

||| Unit tests for environment lookup, raw coercion, fallback reconstruction,
||| option lookup, and direction metadata.
public export
environmentTests : Results
environmentTests =
  let decimal = MkDecimal 125 2
      original = rawResolved (StringValue "first")
      replacement = rawResolved (StringValue "second")
      environment = putResolved "x" replacement [("x", original)]
      base = rawResolved (StringValue "text") in
  checkAll
    [ ("raw string value", rawString (StringValue "text") == "text")
    , ("raw number value", rawString (NumberValue decimal) == "1.25")
    , ("raw integer value", rawString (IntegerValue (-2)) == "-2")
    , ("raw date value", rawString (DateValue "2026-07-14") == "2026-07-14")
    , ("raw time value", rawString (TimeValue "12:30") == "12:30")
    , ("raw datetime value", rawString (DateTimeValue "2026-07-14T12:30") == "2026-07-14T12:30")
    , ("raw unit value", rawString (UnitValue decimal "meter") == "1.25 meter")
    , ("raw currency value", rawString (CurrencyValue decimal "USD") == "USD 1.25")
    , ("raw fallback value", rawString (FallbackValue "$x") == "$x")
    , ("environment replacement", map (.formatted) (lookupResolved "x" environment) == Just "second")
    , ("environment missing key", isMissing (lookupResolved "missing" environment))
    , ("decimal from number", asDecimal (NumberValue decimal) == Just decimal)
    , ("decimal from integer", asDecimal (IntegerValue 7) == Just (MkDecimal 7 0))
    , ("decimal from string", asDecimal (StringValue "1.25") == Just decimal)
    , ("decimal rejects temporal", asDecimal (DateValue "2026-07-14") == Nothing)
    , ("literal fallback source", fallbackSource (literalExpression "a|b") == "|a\\|b|")
    , ("variable fallback source", fallbackSource (variableExpression "name") == "$name")
    , ("function fallback source", fallbackSource (functionExpression "now") == ":now")
    , ("string option", stringOption "x" [("x", StringValue "value")] == Just "value")
    , ("numeric option rendered as string", stringOption "x" [("x", NumberValue decimal)] == Just "1.25")
    , ("missing option", lookupOption "x" [] == Nothing)
    , ("ltr direction option", rightDirection LTR True (withDirection [("u:dir", StringValue "ltr")] base))
    , ("rtl direction option", rightDirection RTL True (withDirection [("u:dir", StringValue "rtl")] base))
    , ("auto direction option", rightDirection UnknownDirection True (withDirection [("u:dir", StringValue "auto")] base))
    , ("inherit direction option", rightDirection UnknownDirection False (withDirection [("u:dir", StringValue "inherit")] base))
    ]
