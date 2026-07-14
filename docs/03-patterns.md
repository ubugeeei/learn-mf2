# Messages, patterns, text, and escapes

## Simple and complex messages

A simple message consists of one pattern. An empty string is also valid.

```mf2
Hello, {$name}!
```

A message with a declaration or matcher is a complex message. Its body is either a quoted pattern `{{...}}` or a matcher.

```mf2
.local $answer = {42 :number}
{{The answer is {$answer}.}}
```

Structural whitespace in a complex message is ignored, but whitespace inside a pattern is always part of its text.

## Pattern parts

A pattern is a sum of text, expression placeholders, and markup placeholders. [`PatternPart`](../src/MF2/Syntax.idr) represents this directly as `Text | Place | Mark`. By avoiding an early conversion to one string, the compiler can preserve markup and expression metadata safely.

## Escapes

Within a pattern, only `\\`, `\{`, `\}`, and `\|` are escapes. MF2 does not define programming-language escapes such as `\\n`; the outer format is responsible for encoding newlines.

```mf2
Curly braces: \{ and \}; slash: \\; pipe: \|
```

The delimiter for a quoted literal is `|`: `{|spaces and @ special characters|}`.

## Unicode scalar boundary

The grammar permits broad code-point ranges. However, an invalid Unicode scalar that Idris 2's `Char` cannot represent cannot be produced at the parser entry point. This host-language boundary is explicit in the [conformance matrix](appendices/conformance-matrix.md).

## Corresponding implementation

- [`parsePatternLoop`](../src/MF2/Parser/Expression.idr)
- [`parseEscape`](../src/MF2/Parser/Core.idr)
- [`PatternPart`](../src/MF2/Syntax.idr)

## Specifications

- [Messages and their syntax](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#messages-and-their-syntax)
- [Pattern](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#pattern)
- [Escape sequences](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#escape-sequences)
- [Complete ABNF](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/message.abnf)
