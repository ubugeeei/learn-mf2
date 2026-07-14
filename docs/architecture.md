# Architecture

## Dependency direction

```mermaid
flowchart TD
  diagnostic["MF2.Diagnostic"]
  syntax["MF2.Syntax"]
  parserCore["MF2.Parser.Core"]
  parserExpr["MF2.Parser.Expression"]
  parserMessage["MF2.Parser.Message"]
  parser["MF2.Parser facade"]
  ir["MF2.IR"]
  validate["MF2.Validate"]
  decimal["MF2.Decimal"]
  runtimeTypes["MF2.Runtime.Types"]
  runtimeEnvironment["MF2.Runtime.Environment"]
  runtimeHandlers["MF2.Runtime.Handlers"]
  runtimeSelection["MF2.Runtime.Selection"]
  runtimeResolution["MF2.Runtime.Resolution"]
  runtimeFormat["MF2.Runtime.Format"]
  runtime["MF2.Runtime facade"]
  compiler["MF2.Compiler"]
  cli["Main"]

  syntax --> diagnostic
  parserCore --> syntax
  parserExpr --> parserCore
  parserMessage --> parserExpr
  parser --> parserMessage
  ir --> syntax
  validate --> ir
  validate --> syntax
  runtimeTypes --> decimal
  runtimeTypes --> syntax
  runtimeEnvironment --> runtimeTypes
  runtimeHandlers --> runtimeEnvironment
  runtimeSelection --> runtimeTypes
  runtimeResolution --> runtimeHandlers
  runtimeResolution --> runtimeSelection
  runtimeResolution --> ir
  runtimeFormat --> runtimeResolution
  runtime --> runtimeFormat
  compiler --> parser
  compiler --> validate
  compiler --> runtime
  cli --> compiler
```

## Trust boundaries

- `String -> RawMessage`: grammar trust boundary; handles only syntax errors.
- `RawMessage -> CompiledMessage`: semantic trust boundary; handles data-model errors and proof construction.
- `CompiledMessage + Context -> FormatResult`: runtime boundary; handles external inputs, locales, and handler failures.
- `OutputPart -> UI`: presentation and security boundary; handles markup mapping and bidi.

## Design rules

- The parser knows nothing about the runtime function registry.
- The validator knows nothing about locale or input values.
- The runtime does not recheck raw arity.
- Default and custom handlers return the same `ResolvedValue` contract.
- String formatting is built only on top of structured output.
- The compiler core does not depend on a CLDR data bundle.

## Public API

Typical callers need only [`compile`](../src/MF2/Compiler.idr) and [`format`](../src/MF2/Compiler.idr). Editors and other tooling may call [`parse`](../src/MF2/Parser.idr) and [`validate`](../src/MF2/Validate.idr) separately to present syntax and data-model diagnostics independently.
