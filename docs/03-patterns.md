# Message、pattern、text、escape

## simple と complex

simple message は pattern 一つです。空文字列も valid です。

```mf2
Hello, {$name}!
```

declaration または matcher を持つ場合は complex message です。complex body は quoted pattern `{{...}}` または matcher になります。

```mf2
.local $answer = {42 :number}
{{The answer is {$answer}.}}
```

complex message の構造用 whitespace は無視されますが、pattern 内の whitespace は常に text の一部です。

## pattern part

pattern は text、expression placeholder、markup placeholder の和型です。[`PatternPart`](../src/MF2/Syntax.idr) は `Text | Place | Mark` としてこれを直接表します。文字列一つへ早期に潰さないため、markup や expression metadata を安全に保持できます。

## escape

pattern では `\\`、`\{`、`\}`、`\|` のみが escape です。`\\n` のような programming-language escape を MF2 自体は定義しません。outer format が改行の符号化を担当します。

```mf2
Curly braces: \{ and \}; slash: \\; pipe: \|
```

quoted literal の delimiter は `|` です: `{|spaces and @ special characters|}`。

## Unicode scalar boundary

grammar は広い code-point 範囲を許します。一方、Idris 2 の `Char` が表現できない不正 UTF scalar を parser 入口で生成することはできません。この host-language boundary は [conformance matrix](appendices/conformance-matrix.md) に明記しています。

## 対応実装

- [`parsePatternLoop`](../src/MF2/Parser.idr)
- [`parseEscape`](../src/MF2/Parser.idr)
- [`PatternPart`](../src/MF2/Syntax.idr)

## 仕様

- [Messages and their syntax](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#messages-and-their-syntax)
- [Pattern](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#pattern)
- [Escape sequences](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#escape-sequences)
- [Complete ABNF](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/message.abnf)

