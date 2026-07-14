# learn-mf2

This repository is a comprehensive guide to Unicode MessageFormat 2 (MF2). It goes beyond reading the specification: you will implement and study a compiler in Idris 2. The normative baseline is pinned to the published **Unicode LDML Part 9, Version 48.2**.

This project does not use Idris as merely “a functional language with unusual syntax.” It gives distinct types to unparsed input, a well-formed AST, and valid compiled IR; stores matcher arity in `Vect`; and erases the proof that a fallback consists entirely of `*` keys from the runtime representation. Every module is also compiled with `--total`.

## Quick start

```console
$ nix develop
$ make check
$ ./build/exec/mf2 check 'Hello, {$name}!'
valid
$ ./build/exec/mf2 format 'Hello, {$name}!' name=World
Hello, World!
$ ./build/exec/mf2 format \
  '.input {$n :number} .match $n one {{one item}} * {{{$n} items}}' \
  n=2
2 items
```

`make check` builds the project, runs every test, and generates the Idris API documentation. The test suite imports 114 syntax cases, 133 syntax-error cases, 23 data-model cases, and 40 runtime cases from the Unicode Working Group's `LDML48.2` snapshot. Because the suite also contains generated cases, treat the assertion count printed by the test runner as authoritative.

## Learning path

Start with the [learning roadmap](docs/00-learning-path.md). It provides a deliberate sequence for moving back and forth between the specification and the implementation.

1. [Why MF2 exists](docs/01-why-mf2.md)
2. [Environment setup and your first run](docs/02-environment.md)
3. [Messages, patterns, and escapes](docs/03-patterns.md)
4. [Expressions, literals, and variables](docs/04-expressions.md)
5. [Declarations and evaluation](docs/05-declarations.md)
6. [Matchers and variant selection](docs/06-matchers.md)
7. [The error model](docs/07-errors.md)
8. [Default functions](docs/08-functions.md)
9. [Markup, attributes, and bidirectional text](docs/09-markup-bidi.md)
10. [Type-driven design in Idris](docs/10-idris-design.md)
11. [The total parser](docs/11-parser.md)
12. [Semantic validation](docs/12-validation.md)
13. [The runtime and extensions](docs/13-runtime.md)
14. [Testing strategy](docs/14-testing.md)
15. [Security and production boundaries](docs/15-production.md)
16. [How to read the specification](docs/16-spec-reading-guide.md)
17. [Differences in the CLDR 49 draft](docs/17-draft-49.md)

Every standard, specification, and official fixture referenced by the project is collected in the [complete specification index](docs/appendices/spec-index.md). See the [conformance matrix](docs/appendices/conformance-matrix.md) for a requirement-by-requirement account of implemented behavior and intentional boundaries.

## Implementation entry points

- [`MF2.Parser`](src/MF2/Parser.idr): public parser façade over [core cursor mechanics](src/MF2/Parser/Core.idr), [expressions and patterns](src/MF2/Parser/Expression.idr), and [messages and matchers](src/MF2/Parser/Message.idr)
- [`MF2.Syntax`](src/MF2/Syntax.idr): the well-formed but unvalidated data model
- [`MF2.Validate`](src/MF2/Validate.idr): data-model error accumulation and type refinement
- [`MF2.IR`](src/MF2/IR.idr): IR built around `Vect (S n)`, `AllCatchall`, and erased proofs
- [`MF2.Decimal`](src/MF2/Decimal.idr): arbitrary-precision decimal arithmetic
- [`MF2.Runtime`](src/MF2/Runtime.idr): public runtime façade over [runtime types](src/MF2/Runtime/Types.idr), [default handlers](src/MF2/Runtime/Handlers.idr), [resolution and selection](src/MF2/Runtime/Resolution.idr), and [structured formatting](src/MF2/Runtime/Format.idr)
- [`MF2.Compiler`](src/MF2/Compiler.idr): the public compile and format API
- [`Main`](src/Main.idr): the CLI
- [`TestMain`](tests/TestMain.idr): property tables and the official fixture runner
- [`TypeLevel`](tests/TypeLevel.idr): examples where successful compilation is itself the test

## Important scope boundary

The compiler front end—syntax, data-model validation, and typed matcher IR—is tested against the LDML 48.2 official fixtures. The runtime is a dependency-free reference backend designed to make the specification algorithms inspectable. It recognizes every default function name, but it does not bundle the complete CLDR locale dataset. Production-quality formatting for numbers, currencies, units, dates, and times across all locales is therefore connected through the handler boundary to ICU or a comparable backend. This is an explicit boundary, not an undocumented limitation; the [conformance matrix](docs/appendices/conformance-matrix.md) records it requirement by requirement.

## License

The project itself is licensed under the MIT License. Data derived from official Unicode fixtures is covered by [`tests/LICENSE.unicode`](tests/LICENSE.unicode), with provenance pinned in [`tests/NOTICE.md`](tests/NOTICE.md).
