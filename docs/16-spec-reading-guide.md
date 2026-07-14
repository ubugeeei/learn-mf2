# How to read the specification

## Pin the version first

Start by checking the document header's version and status. This course's normative baseline is [LDML Part 9 Version 48.2](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html). In the Working Group repository, use the [`LDML48.2` tag](https://github.com/unicode-org/message-format-wg/tree/LDML48.2).

Unversioned URLs and the `main` branch will change. Do not use them as evidence for fixture or conformance claims.

## Recommended reading order

1. Read the terminology and stability policy in the Introduction.
2. Read all of Syntax, then compare it with the ABNF.
3. Study resolved values and fallback under Formatting.
4. Execute the pattern-selection algorithm by hand.
5. Use Errors to confirm phase boundaries.
6. Read default functions in the order string, number, then date/time.
7. Read the Unicode namespace and bidi handling.
8. Read the interchange data model.
9. Finish with Security Considerations.

## Normative and non-normative material

Examples help understanding, but are not normative. MUST, SHOULD, and MAY have their BCP 14 meanings. Implementation decisions should be checked against the prose requirements, ABNF, error definitions, and test fixtures together.

## When the specification and tests appear to disagree

1. Confirm that both come from the same release tag.
2. Check optional and draft tags in the fixture schema.
3. Determine whether the output is implementation-dependent.
4. Search for a specification issue or corrigendum.
5. Preserve a minimal reproduction instead of editing the fixture by guesswork.

## Complete index

Every normative and non-normative source referenced by this repository is collected in the [complete specification index](appendices/spec-index.md).
