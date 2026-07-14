# Runtime、resolution、extension

## Context

[`Context`](../src/MF2/Runtime.idr) は locale、message direction、input mapping、custom function registry、bidi policy を持ちます。compile 可能性と runtime context の充足を分離します。

## resolution pipeline

1. input values を `ResolvedValue` に包む。
2. declaration を source order で一度解決。
3. matcher selector の selection capability を確認。
4. variant を source order で比較。
5. 選ばれた pattern だけを解決。
6. structured parts を生成。
7. string target なら markup を空にし bidi strategy を適用。

`ResolvedValue` は raw value だけでなく、formatted representation、selection behavior、direction、isolation、fallback flag を持ちます。function handler の返り値を単なる `String` にしないのがポイントです。

## custom registry

`Registry` は `(Identifier, FunctionHandler)` の list です。default function にない名前は registry を探し、なければ unknown-function と fallback になります。

handler へ `Maybe ResolvedValue` を渡すため、annotation を重ねるときに operand の resolved selection や option-derived representation を引き継げます。公式 pattern-selection fixture の `decimalPlaces` inheritance もこの境界でテストしています。

## structured output

`formatToParts` は `TextOutput`、`ExpressionOutput`、`MarkupOutput` を返します。`formatToString` はその上に作った convenience layer です。DOM、AttributedString、terminal styling を作る場合は parts を使います。

## 対応実装

- [`ResolvedValue`](../src/MF2/Runtime.idr)
- [`resolveExpression`](../src/MF2/Runtime.idr)
- [`selectPattern`](../src/MF2/Runtime.idr)
- [`formatToParts`](../src/MF2/Runtime.idr)
- [`formatToString`](../src/MF2/Runtime.idr)

## 仕様

- [Formatting](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#formatting)
- [Option resolution](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#option-resolution)
- [Function handler](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#function-handler)

