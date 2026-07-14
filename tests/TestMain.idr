module TestMain

import System
import MF2.Compiler
import MF2.Decimal
import MF2.Diagnostic
import MF2.IR
import MF2.Parser
import MF2.Runtime
import MF2.Syntax
import OfficialFixtures
import OfficialRuntimeFixtures

%default total

record Results where
  constructor MkResults
  passed : Nat
  failed : Nat
  messages : List String

empty : Results
empty = MkResults 0 0 []

combine : Results -> Results -> Results
combine left right = MkResults
  (left.passed + right.passed)
  (left.failed + right.failed)
  (left.messages ++ right.messages)

success : Results
success = MkResults 1 0 []

failure : String -> Results
failure message = MkResults 0 1 [message]

check : String -> Bool -> Results
check label True = success
check label False = failure label

runValidSyntax : List Fixture -> Results
runValidSyntax [] = empty
runValidSyntax (fixture :: rest) =
  let current = case parse fixture.source of
        Right _ => success
        Left diagnostic => failure
          ("official valid syntax failed: " ++ fixture.description ++ "\n  " ++ show diagnostic
            ++ "\n  source: " ++ fixture.source) in
      combine current (runValidSyntax rest)

runSyntaxErrors : List Fixture -> Results
runSyntaxErrors [] = empty
runSyntaxErrors (fixture :: rest) =
  let current = case parse fixture.source of
        Left diagnostic => check
          ("wrong parser diagnostic for: " ++ fixture.source)
          (diagnostic.kind == SyntaxError)
        Right _ => failure
          ("official syntax error was accepted: " ++ fixture.description
            ++ "\n  source: " ++ fixture.source) in
      combine current (runSyntaxErrors rest)

hasKind : String -> List Diagnostic -> Bool
hasKind expected [] = False
hasKind expected (diagnostic :: rest) =
  show diagnostic.kind == expected || hasKind expected rest

runDataModelErrors : List ErrorFixture -> Results
runDataModelErrors [] = empty
runDataModelErrors (fixture :: rest) =
  let current = if fixture.expected == "data-model-error"
        then case compile fixture.source of
          Right _ => success
          Left error => failure
            ("official valid normalization case failed: " ++ fixture.source ++ "\n  " ++ show error)
        else case compile fixture.source of
          Left (ValidationFailure diagnostics) => check
            ("wrong semantic error for: " ++ fixture.source
              ++ "\n  expected: " ++ fixture.expected
              ++ "\n  actual: " ++ show (map (.kind) diagnostics))
            (hasKind fixture.expected diagnostics)
          Left (ParseFailure diagnostic) => failure
            ("semantic fixture failed parsing: " ++ fixture.source ++ "\n  " ++ show diagnostic)
          Right _ => failure
            ("official data-model error was accepted: " ++ fixture.source) in
      combine current (runDataModelErrors rest)

naturalsDown : Nat -> List Nat
naturalsDown Z = [0]
naturalsDown (S value) = S value :: naturalsDown value

integerLiterals : List String
integerLiterals =
  let positives = map show (naturalsDown 150)
      negatives = map (\value => "-" ++ show value) (naturalsDown 150) in
      positives ++ negatives

decimalRoundTrips : List String -> Results
decimalRoundTrips [] = empty
decimalRoundTrips (source :: rest) =
  let current = case parseDecimal source of
        Nothing => failure ("decimal parser rejected: " ++ source)
        Just value => check ("decimal round-trip changed: " ++ source)
                            (renderDecimal value == source || source == "-0") in
      combine current (decimalRoundTrips rest)

decimalEdgeCases : Results
decimalEdgeCases =
  combine
    (decimalRoundTrips ["0.1", "1.25", "-1234.567"])
    (combine
      (check "positive exponent" (map renderDecimal (parseDecimal "1e3") == Just "1000"))
      (combine
        (check "negative exponent" (map renderDecimal (parseDecimal "1e-3") == Just "0.001"))
        (combine
          (check "decimal exponent" (map renderDecimal (parseDecimal "1.2e+2") == Just "120"))
          (combine
            (check "leading zero must be rejected" (parseDecimal "01" == Nothing))
            (combine
              (check "empty fraction must be rejected" (parseDecimal "1." == Nothing))
              (check "positive sign must be rejected" (parseDecimal "+1" == Nothing)))))))

record FormatCase where
  constructor MkFormatCase
  label : String
  source : String
  inputs : List (String, Value)
  locale : String
  expected : String

runtimeCases : List FormatCase
runtimeCases =
  [ MkFormatCase "plain text" "hello" [] "en" "hello"
  , MkFormatCase "variable" "Hello, {$name}!" [("name", StringValue "Ada")] "en" "Hello, Ada!"
  , MkFormatCase "literal" "Value: {|a b|}" [] "en" "Value: a b"
  , MkFormatCase "escape" "\\{x\\}" [] "en" "{x}"
  , MkFormatCase "markup is empty in strings" "a{#b}b{/b}c" [] "en" "abc"
  , MkFormatCase "number" "{12.50 :number}" [] "en" "12.5"
  , MkFormatCase "integer truncation" "{-12.9 :integer}" [] "en" "-12"
  , MkFormatCase "offset add" "{1 :offset add=2}" [] "en" "3"
  , MkFormatCase "offset subtract" "{3 :offset subtract=2}" [] "en" "1"
  , MkFormatCase "percent" "{0.25 :percent}" [] "en" "25%"
  , MkFormatCase "currency" "{12 :currency currency=USD}" [] "en" "USD 12"
  , MkFormatCase "unit" "{12 :unit unit=meter}" [] "en" "12 meter"
  , MkFormatCase "date" "{|2026-07-14| :date}" [] "en" "2026-07-14"
  , MkFormatCase "fallback variable" "{$missing}" [] "en" "{$missing}"
  , MkFormatCase "fallback function" "{:example:missing}" [] "en" "{:example:missing}"
  , MkFormatCase "exact selector"
      ".input {$n :number} .match $n 1 {{exact}} one {{plural}} * {{other}}"
      [("n", NumberValue (MkDecimal 1 0))] "en" "exact"
  , MkFormatCase "English plural"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 1 0))] "en" "one"
  , MkFormatCase "English plural fallback"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 2 0))] "en" "other"
  , MkFormatCase "Japanese plural"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 1 0))] "ja" "other"
  , MkFormatCase "ordinal"
      ".input {$n :number select=ordinal} .match $n two {{second}} * {{other}}"
      [("n", NumberValue (MkDecimal 2 0))] "en" "second"
  , MkFormatCase "two selectors"
      ".input {$a :string} .input {$b :string} .match $a $b x y {{both}} x * {{first}} * * {{none}}"
      [("a", StringValue "x"), ("b", StringValue "y")] "en" "both"
  , MkFormatCase "indirect selector annotation"
      ".input {$a :string} .local $b = {$a} .match $b x {{yes}} * {{no}}"
      [("a", StringValue "x")] "en" "yes"
  ]

runRuntimeCases : List FormatCase -> Results
runRuntimeCases [] = empty
runRuntimeCases (test :: rest) =
  let context = MkContext test.locale LTR test.inputs [] False
      current = case format context test.source of
        Left error => failure ("runtime case did not compile: " ++ test.label ++ "\n  " ++ show error)
        Right (actual, errors) => check
          ("runtime mismatch: " ++ test.label ++ "\n  expected: " ++ test.expected
            ++ "\n  actual: " ++ actual ++ "\n  errors: " ++ show errors)
          (actual == test.expected) in
      combine current (runRuntimeCases rest)

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

record SemanticCase where
  constructor MkSemanticCase
  source : String
  expected : ErrorKind

semanticCases : List SemanticCase
semanticCases =
  [ MkSemanticCase ".input {$x} .match $x one {{one}} * {{other}}" MissingSelectorAnnotation
  , MkSemanticCase ".input {$x :string} .match $x one {{one}}" MissingFallbackVariant
  , MkSemanticCase ".input {$x :string} .match $x * * {{bad}}" VariantKeyMismatch
  , MkSemanticCase ".input {$x} .input {$x} {{bad}}" DuplicateDeclaration
  , MkSemanticCase "{x :f a=1 a=2}" DuplicateOptionName
  , MkSemanticCase ".input {$x :string} .match $x * {{a}} * {{b}}" DuplicateVariant
  ]

runSemanticCases : List SemanticCase -> Results
runSemanticCases [] = empty
runSemanticCases (test :: rest) =
  let current = case compile test.source of
        Left (ValidationFailure diagnostics) => check
          ("missing semantic diagnostic " ++ show test.expected ++ " for " ++ test.source)
          (any (\diagnostic => diagnostic.kind == test.expected) diagnostics)
        _ => failure ("semantic case unexpectedly compiled: " ++ test.source) in
      combine current (runSemanticCases rest)

printFailures : List String -> IO ()
printFailures [] = pure ()
printFailures (message :: rest) = do
  putStrLn ("FAIL: " ++ message)
  printFailures rest

main : IO ()
main = do
  let results = combine (runValidSyntax validSyntax)
              (combine (runSyntaxErrors syntaxErrors)
              (combine (runDataModelErrors dataModelErrors)
              (combine (decimalRoundTrips integerLiterals)
              (combine decimalEdgeCases
              (combine (runRuntimeCases runtimeCases)
              (combine (runOfficialRuntime officialRuntime)
                       (runSemanticCases semanticCases)))))))
  printFailures results.messages
  putStrLn (show results.passed ++ " passed; " ++ show results.failed ++ " failed")
  if results.failed == 0 then pure () else exitFailure
