# Total recursive-descent parser

## なぜ parser combinator dependency を使わないか

このリポジトリでは ABNF と code の対応、source span、fuel による termination を見える形にするため parser を実装しています。production で dependency を避けること自体が目的ではなく、grammar のどの制約をどこで実装するかを学ぶためです。

## cursor

`Cursor` は残りの `List Char` と code-point offset を持ちます。byte offset にしないため、Unicode source の diagnostic span が grammar の単位と一致します。

## fuel

`parsePatternLoop : Nat -> ...` のように、相互再帰する production は source length から計算した fuel を減らします。Idris termination checker は path ごとの input consumption を推測する必要がありません。

## grammar mapping

| ABNF | implementation |
|---|---|
| `message` | `parse` / `parseComplex` |
| `pattern` | `parsePatternLoop` |
| `placeholder` | `parsePlaceholder` |
| `expression` | `parseExpression` |
| `markup` | `parseMarkup` |
| `declaration` | `parseDeclarations` |
| `matcher` | `parseSelectors` + `parseVariants` |
| `literal` | `parseLiteral` |
| `identifier` | `parseIdentifier` |

## whitespace の罠

MF2 の `s` は required whitespace、`o` は optional whitespace です。Bidi mark/isolate は両者の周辺に現れられます。simple pattern の whitespace は text、complex structure の whitespace は insignificant なので、早期に一括 trim してはいけません。

## official syntax fixtures

[`OfficialFixtures`](../tests/OfficialFixtures.idr) は 48.2 の valid syntax 114 件と syntax-error 133 件をそのまま実行します。parser を修正したら、手元の example だけでなく全 fixture を回してください。

## 仕様

- [Syntax](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/syntax.md)
- [ABNF](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/message.abnf)
- [RFC 5234: ABNF](https://www.rfc-editor.org/rfc/rfc5234)

