module MF2.Runtime.Fixtures.Test

import MF2.Compiler
import MF2.Decimal
import MF2.Diagnostic
import MF2.Runtime
import MF2.Syntax
import MF2.Runtime.Fixtures
import MF2.Testing

%default total

testDecimal : ResolvedValue -> Maybe Decimal
testDecimal resolved = case resolved.unwrapped of
  NumberValue decimal => Just decimal
  IntegerValue value => Just (MkDecimal value 0)
  StringValue value => parseDecimal value
  _ => Nothing

testOption : String -> List (String, Value) -> Maybe String
testOption name [] = Nothing
testOption name ((candidate, value) :: rest) =
  if name == candidate
     then Just (case value of
       StringValue value => value
       NumberValue value => renderDecimal value
       IntegerValue value => show value
       _ => "")
     else testOption name rest

containsDot : String -> Bool
containsDot source = any (== '.') (unpack source)

testFunction : Bool -> Bool -> FunctionContext -> Maybe ResolvedValue
            -> List (String, Value) -> Either Diagnostic ResolvedValue
testFunction selectable formattable context Nothing options =
  Left (point BadOperand 0 "test function requires an operand")
testFunction selectable formattable context (Just operand) options = case testDecimal operand of
  Nothing => Left (point BadOperand 0 "test function requires a numeric operand")
  Just decimal =>
    let inheritedExact = case operand.selection of
          NumberSelection _ exact _ => exact
          _ => renderDecimal decimal
        decimalPlaces = case testOption "decimalPlaces" options of
          Just value => value
          Nothing => if containsDot inheritedExact then "1" else "0"
        fails = case testOption "fails" options of
          Just value => value
          Nothing => "never" in
    if decimalPlaces /= "0" && decimalPlaces /= "1"
       then Left (point BadOption 0 "decimalPlaces must be zero or one")
    else if (fails == "always") || (fails == "format" && formattable)
       then Left (point BadOption 0 "test function formatting failure")
    else let base = renderDecimal decimal
             exact = if decimalPlaces == "1" && not (containsDot base)
                        then base ++ ".0" else base
             selection = if selectable && fails /= "select"
                            then NumberSelection decimal exact "exact"
                            else NoSelection in
         Right (MkResolvedValue (NumberValue decimal) exact selection LTR False False)

testRegistry : Registry
testRegistry =
  [ (MkIdentifier (Just "test") "function", MkFunctionHandler (testFunction True True))
  , (MkIdentifier (Just "test") "select", MkFunctionHandler (testFunction True False))
  , (MkIdentifier (Just "test") "format", MkFunctionHandler (testFunction False True))
  ]

||| Run the pinned fallback, pattern-selection, and Unicode namespace fixtures.
public export
runOfficialRuntime : List OfficialRuntime -> Results
runOfficialRuntime [] = empty
runOfficialRuntime (test :: rest) =
  let context = MkContext test.locale test.direction test.inputs testRegistry test.bidi
      current = case format context test.source of
        Left error => failure
          ("official runtime fixture did not compile: " ++ test.description
            ++ "\n  " ++ show error ++ "\n  source: " ++ test.source)
        Right (actual, errors) => check
          ("official runtime mismatch: " ++ test.description
            ++ "\n  expected: " ++ test.expected ++ "\n  actual: " ++ actual
            ++ "\n  errors: " ++ show errors ++ "\n  source: " ++ test.source)
          (actual == test.expected) in
      combine current (runOfficialRuntime rest)
