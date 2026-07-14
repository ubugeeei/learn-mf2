# Error taxonomy and fallback

MF2 errors are distinguished by the phase in which they are discovered.

| Class | Example | Type in this implementation |
|---|---|---|
| Syntax Error | Missing brace, invalid escape | `ParseFailure Diagnostic` |
| Data Model Error | Key arity, fallback, duplicate | `ValidationFailure (List Diagnostic)` |
| Resolution Error | Unresolved variable, unknown function | `FormatResult.errors` |
| Message Function Error | Invalid operand, option, or key | `FormatResult.errors` |

## Separate syntax from the data model

`.input {$x} .match $x one {{one}} * {{other}}` conforms to the grammar, but it is invalid because its selector lacks an annotation. If the parser rejected it, tooling could not distinguish broken syntax from a semantic constraint violation.

## Error accumulation

The parser stops at the first syntax error. The validator accumulates as many independent data-model errors as possible. At runtime, fallback output and diagnostics are returned together.

## Fallback representations

- An unresolved `$name` becomes `{$name}`.
- A function failure with a literal operand becomes `{|literal|}`.
- A function without an operand becomes `{:namespace:name}`.
- If a fallback is referenced again through a local variable, it becomes `{$local}` using that variable's name.

A valid message must produce a formatted result even when runtime errors occur.

## Corresponding implementation

- [`ErrorKind`](../src/MF2/Diagnostic.idr)
- [`CompileError`](../src/MF2/Compiler.idr)
- [`validate`](../src/MF2/Validate.idr)
- [`fallbackSource`](../src/MF2/Runtime/Environment.idr)

## Specifications

- [Errors](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#errors)
- [Fallback resolution](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#fallback-resolution)
- [Formatting fallback values](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#formatting-fallback-values)
