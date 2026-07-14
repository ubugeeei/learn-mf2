module Support.Results

%default total

public export
record Results where
  constructor MkResults
  passed : Nat
  failed : Nat
  messages : List String

public export
empty : Results
empty = MkResults 0 0 []

public export
combine : Results -> Results -> Results
combine left right = MkResults
  (left.passed + right.passed)
  (left.failed + right.failed)
  (left.messages ++ right.messages)

public export
success : Results
success = MkResults 1 0 []

public export
failure : String -> Results
failure message = MkResults 0 1 [message]

public export
check : String -> Bool -> Results
check label True = success
check label False = failure label
