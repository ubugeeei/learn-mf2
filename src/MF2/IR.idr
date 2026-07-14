module MF2.IR

import Data.Vect
import MF2.Syntax

%default total

||| A selector can only be constructed when validation has found a direct or
||| indirect function annotation. There is no `Maybe FunctionRef` here: the
||| missing-annotation state is unrepresentable after compilation.
public export
record Selector where
  constructor MkSelector
  variable : String
  annotation : FunctionRef

||| A validated variant whose number of keys is part of its type.
public export
record Variant (arity : Nat) where
  constructor MkVariant
  keys : Vect arity Key
  value : Pattern

||| A proposition that every key in a vector is the catch-all key. The proof is
||| erased at runtime but makes an invalid fallback impossible to construct
||| accidentally in validated code.
public export
data AllCatchall : Vect arity Key -> Type where
  EmptyCatchall : AllCatchall []
  NextCatchall : AllCatchall rest -> AllCatchall (Catchall :: rest)

||| A fallback variant packages its key vector with a machine-checked proof
||| that every position is `*`.
public export
record FallbackVariant (arity : Nat) where
  constructor MkFallbackVariant
  keys : Vect arity Key
  value : Pattern
  0 allCatchall : AllCatchall keys

||| A matcher always has at least one selector (`Vect (S tail)`). Every variant
||| carries exactly the same arity, and a fallback variant is stored explicitly.
||| These three grammar invariants need no runtime checks in the formatter.
public export
record MatchPlan (tail : Nat) where
  constructor MkMatchPlan
  selectors : Vect (S tail) Selector
  variants : List (Variant (S tail))
  fallback : FallbackVariant (S tail)

||| The validated body. The existential tail preserves the matcher arity while
||| allowing callers to store compiled messages without knowing it statically.
public export
data CompiledBody : Type where
  Static : Pattern -> CompiledBody
  Dynamic : (tail : Nat) -> MatchPlan tail -> CompiledBody

||| A message that has passed both parsing and all stable data-model checks.
||| Construction is intentionally exported for teaching and tooling; production
||| callers should obtain values through `MF2.Compiler.compile`.
public export
record CompiledMessage where
  constructor MkCompiledMessage
  declarations : List Declaration
  body : CompiledBody
