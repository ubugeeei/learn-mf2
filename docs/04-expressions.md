# Expression、literal、variable、option、attribute

expression は `{...}` 内にあり、operand と function annotation の有無で三種類になります。

```mf2
{horse}
{$name}
{:app:now}
{$n :number select=exact}
```

## operand

literal は function なしなら常に string です。`{42}` は number ではなく text `42`。number に解決するには `{42 :number}` と書きます。

variable は `$name` で参照します。declaration がなければ formatting context の implicit input を探します。見つからなければ unresolved-variable となり、`{$name}` という fallback output を生成します。

## function と namespace

function は `:identifier` で annotation します。default function は namespace なし、application-defined function は `:app:name` のように namespace を付けるべきです。

## option

option は `name=value` です。value は literal または variable。順序は意味を持たず、同名 option の重複は compile-time の data-model error です。

```mf2
{$amount :currency currency=USD currencyDisplay=code}
```

## attribute

attribute は function handler へ渡す option ではなく、tooling や output metadata のために保持されます: `{$name @source=profile @important}`。

[`Expression`](../src/MF2/Syntax.idr) は `operand : Maybe Operand` と `function : Maybe FunctionRef` を分け、[`OutputPart`](../src/MF2/Runtime.idr) は attribute を structured output に残します。

## 対応実装

- [`parseExpression`](../src/MF2/Parser.idr)
- [`parseFunction`](../src/MF2/Parser.idr)
- [`resolveExpression`](../src/MF2/Runtime.idr)
- [`Expression`](../src/MF2/Syntax.idr)

## 仕様

- [Expressions](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#expressions)
- [Options](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#options)
- [Attributes](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#attributes)
- [Expression resolution](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#expression-resolution)

