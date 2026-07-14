module MF2.Decimal.Test

import MF2.Decimal
import MF2.Testing

%default total

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

rendersAs : String -> String -> Bool
rendersAs source expected = map renderDecimal (parseDecimal source) == Just expected

invalidDecimal : String -> (String, Bool)
invalidDecimal source = ("invalid decimal accepted: " ++ source, parseDecimal source == Nothing)

||| Generated round trips plus focused grammar, normalization, and arithmetic
||| tests for the exact-decimal implementation.
public export
decimalTests : Results
decimalTests = combineAll
  [ decimalRoundTrips integerLiterals
  , decimalRoundTrips ["0.1", "1.25", "-1234.567"]
  , checkAll
      [ ("positive exponent", rendersAs "1e3" "1000")
      , ("negative exponent", rendersAs "1e-3" "0.001")
      , ("signed exponent", rendersAs "1.2e+2" "120")
      , ("negative coefficient normalization", rendersAs "-0.0100" "-0.01")
      , ("zero normalization", rendersAs "-0" "0")
      , ("large coefficient", rendersAs "999999999999999999999" "999999999999999999999")
      ]
  , checkAll (map invalidDecimal
      ["01", "1.", "+1", "", "-", ".1", "1e", "1e+", "--1", "1 2"])
  , checkAll
      [ ("truncate positive toward zero", map (renderDecimal . truncateDecimal) (parseDecimal "12.9") == Just "12")
      , ("truncate negative toward zero", map (renderDecimal . truncateDecimal) (parseDecimal "-12.9") == Just "-12")
      , ("add whole to fraction", map (renderDecimal . (\value => addWhole value 2)) (parseDecimal "1.25") == Just "3.25")
      , ("subtract whole from fraction", map (renderDecimal . (\value => addWhole value (-2))) (parseDecimal "1.25") == Just "-0.75")
      , ("multiply positive", map (renderDecimal . (\value => multiplyWhole value 100)) (parseDecimal "0.125") == Just "12.5")
      , ("multiply negative", map (renderDecimal . (\value => multiplyWhole value (-3))) (parseDecimal "2.5") == Just "-7.5")
      , ("whole value succeeds", (parseDecimal "42" >>= wholeValue) == Just 42)
      , ("whole value rejects fraction", (parseDecimal "4.2" >>= wholeValue) == Nothing)
      ]
  ]
