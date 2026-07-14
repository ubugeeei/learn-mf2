# Using the full potential of Idris

## Separate phases with types

Untrusted source becomes `RawMessage` through [`parse`](../src/MF2/Parser/Message.idr). At that point it satisfies the grammar, but its data-model constraints have not been validated. Only [`validate`](../src/MF2/Validate.idr) can produce a `CompiledMessage`.

```text
String --parse--> RawMessage --validate--> CompiledMessage
```

With a single large AST and an `isValid : Bool` field, every formatter would need to trust that boolean. Separate types make it impossible for a raw state to reach a formatter argument.

## Put arity in an index

`Variant n` contains `Vect n Key`. The selectors in `MatchPlan tail` have type `Vect (S tail) Selector`. Consequently, an attempt such as the following cannot compile:

```idris
-- Type mismatch: a one-key variant cannot be passed to two selectors.
bad : MatchPlan 1
```

There is no need to run this negative example in a test runner: the compiler rejects it first. [`MF2.IR.Test`](../src/MF2/IR/Test.idr) contains positive witnesses beside the IR.

## Propositions and erased proofs

The property that every fallback key is `Catchall` is represented as a proposition.

```idris
data AllCatchall : Vect arity Key -> Type where
  EmptyCatchall : AllCatchall []
  NextCatchall : AllCatchall rest -> AllCatchall (Catchall :: rest)
```

The proof field in `FallbackVariant` has multiplicity `0`, so it is erased from the runtime representation. The guarantee is strong and its runtime cost is zero.

## Totality

The package is built with `--total`. The parser converts its mutually recursive grammar into structural recursion using fuel, and decimal normalization recurses over the scale. No partial function or unchecked index access appears on the formatting path.

## An existential body through a dependent pair

Matcher arity is a runtime value when a message is loaded. `Dynamic : (tail : Nat) -> MatchPlan tail -> CompiledBody` packages the arity together with the plan whose type depends on it.

## What deliberately remains outside the types

The locale, function registry, and presence of external inputs belong to the runtime context. Encoding all of them in compile-time types would make dynamic translation loading and plugin handlers awkward. Idris reaches its full potential here not by putting everything in a type, but by moving each statically knowable invariant into the type at the correct boundary.

## Corresponding implementation

- [`IR`](../src/MF2/IR.idr)
- [`Validate`](../src/MF2/Validate.idr)
- [`Decimal`](../src/MF2/Decimal.idr)
- [`MF2.IR.Test`](../src/MF2/IR/Test.idr)
