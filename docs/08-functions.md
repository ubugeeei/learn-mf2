# Default function 完全ガイド

function は syntax の一部であると同時に runtime extension point です。48.2 の default function 名を reference runtime はすべて受理します。

| function | format | select | reference backend |
|---|---:|---:|---|
| `:string` | yes | exact string | 実装済み |
| `:number` | yes | exact/cardinal/ordinal | exact decimal + 教学用 locale rules |
| `:integer` | yes | exact/cardinal/ordinal | 0 方向への truncate |
| `:offset` | yes | numeric | exact integer add/subtract |
| `:percent` | yes | numeric | exact multiplication + `%` |
| `:currency` | yes | no | locale-neutral `CODE value` |
| `:unit` | yes | no | locale-neutral `value unit`、48.2 では Draft |
| `:datetime` | yes | no | temporal handler seam |
| `:date` | yes | no | temporal handler seam |
| `:time` | yes | no | temporal handler seam |

## exact decimal

MF2 `number-literal` は arbitrary precision です。binary `Double` では `0.1` や非常に大きな integer を正確に保持できません。[`Decimal`](../src/MF2/Decimal.idr) は `coefficient : Integer` と `scale : Nat` で表し、exponent notation も lossless に読みます。

```mf2
{1.25 :number}
{1e-3 :number}
{-12.9 :integer}
{3 :offset subtract=2}
```

## locale data boundary

function の「名前を受理する」ことと、全 option の locale output を独自実装することは別です。grouping、currency symbol、unit preference、calendar、time zone、plural data は CLDR/ICU の大きなデータセットです。本リポジトリは compiler semantics と handler API を自前実装し、production locale backend は `Registry` から注入します。

この境界を曖昧にしないため、built-in の教学用出力と production conformance を [matrix](appendices/conformance-matrix.md) で分けています。

## custom function

```idris
record FunctionHandler where
  run : FunctionContext
      -> Maybe ResolvedValue
      -> List (String, Value)
      -> Either Diagnostic ResolvedValue
```

custom handler は formatting、selection、direction metadata、resolved option inheritance に必要な情報を返せます。application function には namespace を付けます。

## 対応実装

- [`Decimal`](../src/MF2/Decimal.idr)
- [`runDefault`](../src/MF2/Runtime.idr)
- [`FunctionHandler`](../src/MF2/Runtime.idr)

## 仕様

- [Default functions](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#default-functions)
- [`:string`](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/functions/string.md)
- [numeric functions](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/functions/number.md)
- [date/time functions](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/functions/datetime.md)
- [LDML Numbers 48.2](https://www.unicode.org/reports/tr35/tr35-78/tr35-numbers.html)
- [LDML Dates 48.2](https://www.unicode.org/reports/tr35/tr35-78/tr35-dates.html)

