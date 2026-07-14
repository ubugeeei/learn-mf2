# Testing strategy

## Three layers of resistance

1. Compile-time proofs prevent construction of invalid IR.
2. Official conformance fixtures keep the implementation aligned with the Unicode Working Group.
3. Generated and handwritten cases exercise decimal arithmetic, runtime behavior, and regressions broadly.

## Compile-time tests

[`MF2.IR.Test`](../src/MF2/IR/Test.idr) constructs a two-selector plan, a two-key variant, and an all-catch-all proof. Changing a `Vect` length makes type checking fail before the test executable starts.

## Official snapshot

Fixtures are pinned to the `LDML48.2` tag and commit `7f142fb4f1f5ea6ab1eb34ce2b87e918ca9fd331`, not to a mutable `main` branch.

| Upstream suite | Local assertions |
|---|---:|
| `syntax.json` | 114 |
| `syntax-errors.json` | 133 |
| `data-model-errors.json` | 23 |
| `fallback.json` | 8 |
| `pattern-selection.json` | 22 |
| `u-options.json` | 10 |

See [`NOTICE`](../src/MF2/Fixtures/NOTICE.md) for fixture provenance and licensing.

## Colocation

There is no separate `tests/` source tree. Tests live beside the phase they exercise:

- [`Decimal.Test`](../src/MF2/Decimal/Test.idr) covers grammar, normalization, exact arithmetic, and generated round trips.
- [`Parser.Test`](../src/MF2/Parser/Test.idr) consumes the syntax fixtures under `Parser/Fixtures/`.
- [`Validate.Test`](../src/MF2/Validate/Test.idr) consumes data-model fixtures and refinement regressions.
- Runtime unit and integration tests sit under [`Runtime/`](../src/MF2/Runtime.idr), next to Environment, Handlers, Selection, Format, and official fixtures.

[`MF2.TestMain`](../src/MF2/TestMain.idr) only aggregates these phase-local results.

## Generated decimal tests

The suite generates a broad range of positive and negative integers and checks the `parseDecimal`/`renderDecimal` round trip. Fractions, exponents, leading zeros, an empty fractional component, and truncation toward zero also have independent cases.

## Regression table

Table-driven tests cover markup, fallback, every default function and its error paths, environment replacement, option coercion, English/French/Japanese plural behavior, ordinal exceptions, match ranks, multiple selectors, bidi metadata, and indirect annotations.

## Running the suite

```console
$ make test
$ make check
$ nix flake check --print-build-logs
```

Do not trust a fixed test count in prose. Treat the runner's final `N passed; 0 failed` line as the evidence.

## Specifications

- [Unicode MF2 test suite](https://github.com/unicode-org/message-format-wg/tree/LDML48.2/test)
- [Test schema](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/test/schemas/v0/tests.schema.json)
- [Unicode License](https://www.unicode.org/license.txt)
