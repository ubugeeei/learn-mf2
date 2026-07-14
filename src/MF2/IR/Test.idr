module MF2.IR.Test

import Data.Vect
import MF2.Diagnostic
import MF2.IR
import MF2.Syntax
import MF2.Testing

%default total

span : Span
span = MkSpan 0 0

stringFunction : FunctionRef
stringFunction = MkFunctionRef (MkIdentifier Nothing "string") [] span

firstSelector : Selector
firstSelector = MkSelector "first" stringFunction

secondSelector : Selector
secondSelector = MkSelector "second" stringFunction

||| A compile-time proof that both keys in the fallback are catch-alls.
|||
||| Changing either key to `LiteralKey` makes this module fail before the test
||| executable can be generated. The proof is erased from that executable.
twoCatchalls : AllCatchall [Catchall, Catchall]
twoCatchalls = NextCatchall (NextCatchall EmptyCatchall)

fallback : FallbackVariant 2
fallback = MkFallbackVariant [Catchall, Catchall] [Text "fallback"] twoCatchalls

exact : Variant 2
exact = MkVariant [LiteralKey "a", LiteralKey "b"] [Text "exact"]

||| `MatchPlan 1` means one head selector plus one tail selector.
|||
||| Idris therefore proves that both variants have exactly two keys.
public export
twoSelectorPlan : MatchPlan 1
twoSelectorPlan = MkMatchPlan [firstSelector, secondSelector] [exact] fallback

||| Runtime witnesses complementing the compile-time arity proof above.
public export
irTests : Results
irTests = checkAll
  [ ("type-level plan retains two selectors", length (toList twoSelectorPlan.selectors) == 2)
  , ("type-level plan retains one exact variant", length twoSelectorPlan.variants == 1)
  , ("type-level fallback retains two keys", length (toList twoSelectorPlan.fallback.keys) == 2)
  ]
