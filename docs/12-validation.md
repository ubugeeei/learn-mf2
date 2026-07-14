# Semantic validation and type refinement

A message can be invalid even after parsing succeeds. The validator enumerates data-model errors and constructs dependent IR only on success.

## Validation passes

1. Detect duplicate options in each expression and markup node.
2. Check declaration binding and reference history.
3. Build the direct and indirect function-annotation environment.
4. Check variant key arity.
5. Find an all-catch-all fallback.
6. Detect duplicate normalized key lists.
7. Convert each `List` to an exact-sized `Vect`.
8. Construct the `AllCatchall` witness.

## Error accumulation

`Validation value = Either (List Diagnostic) value` collects errors that can be reported independently. It does not force a dependent conversion while arity is invalid; `exactVect` is called only when the error list is empty.

## Indirect annotations

A local variable without its own function may still act as a selector when its operand refers to an annotated declaration. `annotationEnvironment` propagates annotations in declaration order. Forward references are first rejected as duplicate declarations, so this environment cannot contain cycles.

## Proof construction

`proveAllCatchall` traverses `Vect n Key` and returns `AllCatchall keys` only when every key is `Catchall`. The Boolean-style check and proof construction are intentionally combined in one traversal.

## Corresponding implementation

- [`validate`](../src/MF2/Validate.idr)
- [`compileMatch`](../src/MF2/Validate.idr)
- [`proveAllCatchall`](../src/MF2/Validate.idr)
- [`CompiledMessage`](../src/MF2/IR.idr)

## Specifications

- [Well-formed vs valid](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#well-formed-vs-valid-messages)
- [Data model errors](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#data-model-errors)
- [Interchange data model](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#interchange-data-model)
