# Complete guide to default functions

Functions are both part of the syntax and the runtime extension point. The reference runtime recognizes every default function name in Version 48.2.

| Function | Format | Select | Reference backend |
|---|---:|---:|---|
| `:string` | yes | exact string | Implemented |
| `:number` | yes | exact/cardinal/ordinal | Exact decimal plus teaching locale rules |
| `:integer` | yes | exact/cardinal/ordinal | Truncate toward zero |
| `:offset` | yes | numeric | Exact integer addition/subtraction |
| `:percent` | yes | numeric | Exact multiplication plus `%` |
| `:currency` | yes | no | Locale-neutral `CODE value` |
| `:unit` | yes | no | Locale-neutral `value unit`; Draft in 48.2 |
| `:datetime` | yes | no | Temporal handler seam |
| `:date` | yes | no | Temporal handler seam |
| `:time` | yes | no | Temporal handler seam |

## Exact decimals

The MF2 `number-literal` has arbitrary precision. A binary `Double` cannot exactly preserve values such as `0.1` or very large integers. [`Decimal`](../src/MF2/Decimal.idr) uses `coefficient : Integer` and `scale : Nat`, and parses exponent notation without loss.

```mf2
{1.25 :number}
{1e-3 :number}
{-12.9 :integer}
{3 :offset subtract=2}
```

## Locale-data boundary

Recognizing a function name is different from independently implementing localized output for every option. Grouping, currency symbols, unit preferences, calendars, time zones, and plural rules depend on the large CLDR/ICU datasets. This repository implements the compiler semantics and handler API; a production locale backend is injected through `Registry`.

To keep this boundary explicit, the [conformance matrix](appendices/conformance-matrix.md) distinguishes built-in teaching output from production conformance.

## Custom functions

```idris
record FunctionHandler where
  run : FunctionContext
      -> Maybe ResolvedValue
      -> List (String, Value)
      -> Either Diagnostic ResolvedValue
```

A custom handler can return the information required for formatting, selection, direction metadata, and inheritance of resolved options. Application functions should use a namespace.

## Corresponding implementation

- [`Decimal`](../src/MF2/Decimal.idr)
- [`runDefault`](../src/MF2/Runtime/Handlers.idr)
- [text and temporal handlers](../src/MF2/Runtime/Handlers/Text.idr)
- [numeric handlers](../src/MF2/Runtime/Handlers/Numeric.idr)
- [currency and unit handlers](../src/MF2/Runtime/Handlers/Measure.idr)
- [`FunctionHandler`](../src/MF2/Runtime/Types.idr)

## Specifications

- [Default functions](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#default-functions)
- [`:string`](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/functions/string.md)
- [Numeric functions](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/functions/number.md)
- [Date/time functions](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/functions/datetime.md)
- [LDML Numbers 48.2](https://www.unicode.org/reports/tr35/tr35-78/tr35-numbers.html)
- [LDML Dates 48.2](https://www.unicode.org/reports/tr35/tr35-78/tr35-dates.html)
