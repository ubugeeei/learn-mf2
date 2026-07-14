# LDML 48.2 conformance matrix

This table defines implementation boundaries precisely and avoids overstated claims. `yes` means continuously checked by local tests and official fixtures; `reference` means an implementation intended for studying the algorithm; `external` requires a production handler or data backend; and `not yet` means unimplemented.

## Syntax and data model

| Requirement | Status | Evidence |
|---|---|---|
| Simple and complex messages | yes | Official syntax fixtures |
| Declarations | yes | Parser plus duplicate-declaration fixtures |
| Quoted pattern, text, and escapes | yes | Official syntax/error fixtures |
| Expressions, operands, functions, and options | yes | Official syntax fixtures |
| Markup and attributes | yes | Official syntax plus u-options fixtures |
| Matchers, variants, and keys | yes | Official syntax plus pattern-selection fixtures |
| Identifier Unicode ranges | yes within Idris `Char` | Parser character classes |
| Host representation of an unpaired surrogate | not representable | Idris scalar boundary |
| Variant-key arity | yes, type-refined | `Vect n Key` |
| All-catch-all fallback | yes, proved | Erased `AllCatchall` proof |
| Direct/indirect selector annotation | yes | Validator plus fixtures |
| Duplicate options, declarations, and variants | yes | Official data-model fixtures |

## Formatting

| Requirement | Status | Note |
|---|---|---|
| Formatting context and input mapping | yes | `Context` |
| Literal, variable, and function resolution | yes | Official fallback fixtures |
| Options as an order-insensitive mapping | yes | Resolved list after duplicate validation |
| Declaration evaluation at most once | yes | Eager, source-order memoization |
| Fallback representations | yes | Official fallback-output fixtures |
| Pattern selection | yes for supplied selection operations | Official pattern-selection fixtures |
| Exact string selection | yes | Built-in handler |
| Exact numeric selection | yes | Arbitrary-precision decimal |
| Every CLDR plural locale | external | Reference rules cover en/fr/ja/zh/ko for teaching |
| `NormalizeKey` NFC | external | Requires a Unicode-normalization backend |
| Structured parts | yes | `OutputPart` |
| Empty markup in a string target | yes | Runtime plus fixtures |
| Default bidi strategy | yes | Official u-options output fixtures |

## Default functions

| Function | Accepted | Full locale formatting |
|---|---:|---:|
| `:string` | yes | yes for string semantics |
| `:number` | yes | external for complete CLDR options |
| `:integer` | yes | external for complete CLDR options |
| `:offset` | yes | reference exact arithmetic |
| `:currency` | yes | external for symbols and patterns |
| `:percent` | yes | external for locale patterns |
| `:unit` (Draft in 48.2) | yes | external for conversion and preferences |
| `:datetime` | yes | external for calendars, skeletons, and TZDB |
| `:date` | yes | external for calendars, skeletons, and TZDB |
| `:time` | yes | external for calendars, skeletons, and TZDB |

“Accepted” means the function does not produce unknown-function. It does not claim that every option combination produces finished locale-specific output. A production backend may return a diagnostic for an unsupported combination.

## Interchange and tooling

| Feature | Status |
|---|---|
| Internal data model | yes |
| JSON `message.json` import/export | not yet |
| XML representation | not yet |
| Source-preserving concrete syntax tree | not yet |
| Rich source locations for every token | partial: expression/declaration/variant/option |

## Test evidence

The suite runs 310 cases from the official `LDML48.2` snapshot—114 syntax, 133 syntax-error, 23 data-model, and 40 runtime cases—plus generated decimal and regression tests. Run `make test` for the authoritative total assertion count.
