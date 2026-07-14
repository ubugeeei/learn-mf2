module TypeLevel

import Data.Vect
import MF2.Diagnostic
import MF2.IR
import MF2.Syntax

%default total

span : Span
span = MkSpan 0 0

stringFunction : FunctionRef
stringFunction = MkFunctionRef (MkIdentifier Nothing "string") [] span

firstSelector : Selector
firstSelector = MkSelector "first" stringFunction

secondSelector : Selector
secondSelector = MkSelector "second" stringFunction

||| This proposition is checked by Idris at compile time and erased from the
||| executable. Changing either key to `LiteralKey` makes this module fail.
twoCatchalls : AllCatchall [Catchall, Catchall]
twoCatchalls = NextCatchall (NextCatchall EmptyCatchall)

fallback : FallbackVariant 2
fallback = MkFallbackVariant [Catchall, Catchall] [Text "fallback"] twoCatchalls

exact : Variant 2
exact = MkVariant [LiteralKey "a", LiteralKey "b"] [Text "exact"]

||| `MatchPlan 1` means one head selector plus one tail selector. Idris proves
||| that both variants have two keys before any test executable can run.
public export
twoSelectorPlan : MatchPlan 1
twoSelectorPlan = MkMatchPlan [firstSelector, secondSelector] [exact] fallback

