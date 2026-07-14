# Markup, attributes, structured output, and bidi

## Markup is not HTML

```mf2
This is {#emphasis}important{/emphasis}.
Icon: {#icon name=warning /}
```

MF2 represents open, close, and standalone markup, but does not require nesting or matching tag names. The application assigns meaning to it. For a string target, markup's default representation is the empty string.

[`OutputPart`](../src/MF2/Runtime/Format.idr) returns markup as structured data. A safe integration maps it to an allowlisted component table instead of concatenating it into HTML source.

## `u:id`

`u:id` identifies a structured part and is ignored in string output. It is useful for distinguishing two otherwise identical placeholders in a UI.

## `u:dir` and the default bidi strategy

Direction values are `ltr`, `rtl`, `auto`, and `inherit`. In plain-string output, the runtime inserts LRI U+2066, RLI U+2067, FSI U+2068, and PDI U+2069 according to the expression direction and message direction.

```mf2
hello {world :string u:dir=rtl}
```

These control characters are difficult to see, but prevent spillover when RTL and LTR text are mixed. The runtime does not guess direction by inspecting formatted text; it receives direction metadata from the handler as `ResolvedValue.direction`.

## Corresponding implementation

- [`Markup`](../src/MF2/Syntax.idr)
- [`MarkupOutput`](../src/MF2/Runtime/Format.idr)
- [`isolateText`](../src/MF2/Runtime/Format.idr)
- [Official u-options fixtures](../tests/OfficialRuntimeFixtures.idr)

## Specifications

- [Markup](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#markup)
- [Unicode namespace](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#unicode-namespace)
- [Handling bidirectional text](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#handling-bidirectional-text)
- [Unicode Bidirectional Algorithm, UAX #9](https://www.unicode.org/reports/tr9/)
