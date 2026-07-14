module Support.DecimalCases

import MF2.Decimal
import Support.Results

%default total

naturalsDown : Nat -> List Nat
naturalsDown Z = [0]
naturalsDown (S value) = S value :: naturalsDown value

public export
integerLiterals : List String
integerLiterals =
  let positives = map show (naturalsDown 150)
      negatives = map (\value => "-" ++ show value) (naturalsDown 150) in
      positives ++ negatives

public export
decimalRoundTrips : List String -> Results
decimalRoundTrips [] = empty
decimalRoundTrips (source :: rest) =
  let current = case parseDecimal source of
        Nothing => failure ("decimal parser rejected: " ++ source)
        Just value => check ("decimal round-trip changed: " ++ source)
                            (renderDecimal value == source || source == "-0") in
      combine current (decimalRoundTrips rest)

public export
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
