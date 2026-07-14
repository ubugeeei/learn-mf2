module MF2.Testing

%default total

||| Aggregate test results without depending on an external test framework.
|||
||| Keeping failures as data lets every test group run before the executable
||| prints a complete report and chooses its exit status.
public export
record Results where
  constructor MkResults
  passed : Nat
  failed : Nat
  messages : List String

||| The identity element for result aggregation.
public export
empty : Results
empty = MkResults 0 0 []

||| Combine independent test groups while preserving failure order.
public export
combine : Results -> Results -> Results
combine left right = MkResults
  (left.passed + right.passed)
  (left.failed + right.failed)
  (left.messages ++ right.messages)

||| Combine a list of independent test groups.
public export
combineAll : List Results -> Results
combineAll [] = empty
combineAll (result :: rest) = combine result (combineAll rest)

||| Record one successful assertion.
public export
success : Results
success = MkResults 1 0 []

||| Record one failed assertion and its diagnostic label.
public export
failure : String -> Results
failure message = MkResults 0 1 [message]

||| Turn a Boolean predicate into one assertion result.
public export
check : String -> Bool -> Results
check label True = success
check label False = failure label

||| Run a compact table of labelled Boolean assertions.
public export
checkAll : List (String, Bool) -> Results
checkAll [] = empty
checkAll ((label, condition) :: rest) =
  combine (check label condition) (checkAll rest)
