# Total recursive-descent parser

## Why there is no parser-combinator dependency

This repository implements its own parser so the correspondence between the ABNF and code, source spans, and fuel-based termination remain visible. Avoiding a dependency is not an end in itself for production; the purpose is to learn exactly where each grammar constraint is enforced.

## Cursor

`Cursor` contains the remaining `List Char` and a code-point offset. Using a code-point rather than byte offset keeps diagnostic spans for Unicode source in the same unit as the grammar.

## Fuel

Mutually recursive productions such as `parsePatternLoop : Nat -> ...` decrement fuel derived from the source length. The Idris termination checker therefore does not need to infer input consumption along every possible path.

## Grammar mapping

| ABNF | Implementation |
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

## The whitespace trap

MF2 uses `s` for required whitespace and `o` for optional whitespace. Bidi marks and isolates may appear around both. Whitespace in a simple pattern is text, while structural whitespace in a complex message is insignificant, so the complete source must never be trimmed up front.

## Official syntax fixtures

[`MF2.Parser.Test`](../src/MF2/Parser/Test.idr) runs all 114 valid syntax cases and all 133 syntax-error cases from the colocated [Version 48.2 fixtures](../src/MF2/Parser/Fixtures.idr). After changing the parser, run the complete fixture set rather than only local examples.

## Specifications

- [Syntax](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/syntax.md)
- [ABNF](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/spec/message.abnf)
- [RFC 5234: ABNF](https://www.rfc-editor.org/rfc/rfc5234)
