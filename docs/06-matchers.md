# Matchers and pattern selection

A matcher consists of one or more selectors and one or more variants.

```mf2
.input {$count :number}
.match $count
0     {{none}}
one   {{one}}
*     {{many}}
```

## Validity requirements

- There is at least one selector.
- Every variant has exactly as many keys as there are selectors.
- At least one fallback variant has `*` for every key.
- Every selector directly or indirectly references a declaration with a function annotation.
- Two variants cannot have the same normalized key list.

The quoted literal `|*|` is a literal star, not the catch-all `*`.

## Selection order

Each selector provides `Match` and `BetterThan` operations over keys. Conceptually, exact numeric or string matches outrank plural or ordinal rule matches, which outrank the catch-all. With multiple selectors, comparisons are lexicographic in source order.

## Enforcing validity with types

The raw parser returns [`RawVariant`](../src/MF2/Syntax.idr), which can represent an incorrect key count. After successful validation, the result is [`MatchPlan`](../src/MF2/IR.idr) with `selectors : Vect (S tail) Selector` and `variants : List (Variant (S tail))`.

Because the index is `S tail`, zero selectors are unrepresentable. The fallback carries an [`AllCatchall`](../src/MF2/IR.idr) proof.

## Corresponding implementation

- [`parseVariants`](../src/MF2/Parser/Message.idr)
- [`compileMatch`](../src/MF2/Validate.idr)
- [`selectBest`](../src/MF2/Runtime/Selection.idr)
- [`MF2.IR.Test`](../src/MF2/IR/Test.idr)

## Specifications

- [Matcher](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#matcher)
- [Pattern selection](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#pattern-selection)
- [Pattern selection examples](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#pattern-selection-examples)
- [CLDR plural rules 48](https://unicode.org/cldr/charts/48/supplemental/language_plural_rules.html)
