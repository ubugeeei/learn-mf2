# Security and production boundaries

## Do not treat message source as code

MF2 function and markup identifiers are keys into an application registry. Never connect them to arbitrary reflection, module loading, or HTML evaluation. The registry must be an explicit allowlist.

## Custom handlers

Give handlers a minimal read-only context and bound their execution time and resource use. Handlers that access the network, file system, or mutable global state make reproducibility and call-by-need semantics much harder to preserve.

## Unicode

- Make invisible characters and bidi controls in identifiers and literals visible in tooling.
- Warn about confusables and mixed scripts in translation editors.
- Apply the NFC normalization required by pattern-selection keys.
- Handle decoding errors in an untrusted outer format before invoking the parser.

The reference runtime does not bundle an NFC library, so production integration must supply canonical equivalence for non-ASCII keys.

## Rich text

Do not concatenate `MarkupOutput` into an HTML string. Map each identifier to an allowlisted component or function, then validate option values within that component.

## Locale backend

Correct number, date, unit, and currency output for every locale requires current CLDR data, TZDB, and calendar implementations. Do not use the reference backend's locale-neutral output as finished production UI; inject an ICU or comparable handler.

## Resource limits

Parser fuel prevents nontermination, but applications should also limit message length, number-literal length, and variant count. Because `Integer` is arbitrary precision, extremely large numeric inputs can exhaust memory.

## Checklist

- Limits for source size, variant count, and literal length
- Registry allowlist and handler timeouts
- Pinned CLDR and TZDB versions
- NFC normalization
- Markup component allowlist
- Diagnostic logging and user-safe fallback
- Translated-message tests over a fixture and locale matrix

## Specifications

- [MF2 Security Considerations](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#security-considerations)
- [Unicode Security Mechanisms, UTS #39](https://www.unicode.org/reports/tr39/)
- [Unicode Normalization Forms, UAX #15](https://www.unicode.org/reports/tr15/)
- [Unicode Bidirectional Algorithm, UAX #9](https://www.unicode.org/reports/tr9/)
