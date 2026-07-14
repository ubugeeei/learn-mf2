# Learning roadmap

The goal of this course is not merely to “use MF2 syntax.” By the end, you should be able to answer the following questions from both the relevant specification section and the corresponding Idris types.

- Where is the distinction between a simple message and a complex message made?
- Why are well-formedness and validity separate phases?
- Why does a selector require a function annotation?
- Why is pattern selection still non-trivial when a fallback variant is mandatory?
- Why can a valid message still produce output after a resolution error?
- How does keeping markup out of raw strings improve safety?
- Where should the responsibilities of locale data and the message compiler be separated?
- Which invariants should dependent types enforce, and which facts belong at runtime?

## Phase 1: read as an MF2 user

Chapters [01](01-why-mf2.md) through [09](09-markup-bidi.md) cover the MF2 data model and runtime semantics. In each chapter, run the examples through the CLI, then follow the links to the matching specification anchor and implementation.

Completion criteria:

- Explain the differences among placeholders, expressions, and markup.
- Write `.input`, `.local`, and `.match` constructs without copying an example.
- Predict the priority of exact keys, plural keys, and `*`.
- Classify syntax, data-model, resolution, and message-function errors.

## Phase 2: read as a compiler author

Chapters [10](10-idris-design.md) through [13](13-runtime.md) focus on the implementation. The central question is why a `RawVariant` stores its keys as `List Key`, while `Variant n` stores them as `Vect n Key`.

Completion criteria:

- Explain why `parse : String -> Either Diagnostic RawMessage` and `validate : RawMessage -> Validation CompiledMessage` are separate.
- Read from the type that `MatchPlan tail` cannot represent zero selectors.
- Explain what it means for the `AllCatchall keys` proof to be erased at runtime.
- Explain why exact decimal behavior must not use `Double`.

## Phase 3: judge conformance and production readiness

Chapters [14](14-testing.md) through [17](17-draft-49.md) cover official fixtures, security, the locale-backend boundary, and draft drift.

Completion criteria:

- Explain the difference between “passes the official fixtures” and “fully conformant for every locale.”
- Assign responsibility for NFC normalization, CLDR plural data, and TZDB.
- Produce an upgrade plan without mixing Version 48.2 and the Version 49 draft.

## Recommended practice loop

Repeat the following in every chapter:

```console
$ nix develop
$ make test
$ ./build/exec/mf2 check '...'
$ ./build/exec/mf2 format '...' name=value
```

To inspect types in the REPL, run `idris2 --repl mf2.ipkg`. After `make docs`, the generated API documentation is available at `build/docs/mf2/index.html`.

## Specifications

- [LDML 48.2 Part 9](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html)
- [Official Quick Start](https://messageformat.unicode.org/docs/quick-start/)
- [Complete specification index](appendices/spec-index.md)
