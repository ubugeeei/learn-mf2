# Runtime, resolution, and extensions

## Read the runtime in dependency order

The runtime is intentionally arranged as a pipeline instead of one large module:

1. [`Types`](../src/MF2/Runtime/Types.idr) defines values, handler contracts, contexts, and structured output.
2. [`Environment`](../src/MF2/Runtime/Environment.idr) owns variable lookup, option resolution, coercion, fallback reconstruction, and `u:dir` metadata.
3. [`Handlers`](../src/MF2/Runtime/Handlers.idr) is a small dispatch table over [text/temporal](../src/MF2/Runtime/Handlers/Text.idr), [numeric](../src/MF2/Runtime/Handlers/Numeric.idr), and [measure](../src/MF2/Runtime/Handlers/Measure.idr) families.
4. [`Selection`](../src/MF2/Runtime/Selection.idr) implements named match ranks and lexicographic variant preference.
5. [`Resolution`](../src/MF2/Runtime/Resolution.idr) orchestrates expressions, declarations, selectors, and handlers.
6. [`Format`](../src/MF2/Runtime/Format.idr) produces structured parts and then the optional plain-string view.

[`MF2.Runtime`](../src/MF2/Runtime.idr) publicly re-exports these phases so application imports remain stable.

## Context

[`Context`](../src/MF2/Runtime/Types.idr) contains the locale, message direction, input mapping, custom function registry, and bidi policy. Whether a message compiles is deliberately separate from whether its runtime context is complete.

## Resolution pipeline

1. Wrap input values as `ResolvedValue` instances.
2. Resolve each declaration once in source order.
3. Check each matcher selector's selection capability.
4. Compare variants in source order.
5. Resolve only the selected pattern.
6. Produce structured parts.
7. For a string target, replace markup with empty text and apply the bidi strategy.

`ResolvedValue` contains more than a raw value: it also carries its formatted representation, selection behavior, direction, isolation policy, and fallback state. A function handler must therefore return more than a `String`.

## Custom registry

`Registry` is a list of `(Identifier, FunctionHandler)` pairs. A name not provided by a default function is looked up in the registry. If absent there too, resolution returns an unknown-function diagnostic and a fallback.

Handlers receive `Maybe ResolvedValue`, allowing a new annotation to inherit resolved selection behavior or option-derived representation from its operand. The official pattern-selection fixtures test `decimalPlaces` inheritance through this boundary.

## Structured output

`formatToParts` returns `TextOutput`, `ExpressionOutput`, and `MarkupOutput`. `formatToString` is a convenience layer built on top. Use the parts API when producing a DOM, `AttributedString`, or terminal styling.

## Colocated tests

Each runtime phase has a test module beside it: [`Environment.Test`](../src/MF2/Runtime/Environment/Test.idr), [`Handlers.Test`](../src/MF2/Runtime/Handlers/Test.idr), [`Selection.Test`](../src/MF2/Runtime/Selection/Test.idr), and [`Format.Test`](../src/MF2/Runtime/Format/Test.idr). Official runtime fixtures and their custom handler are colocated under [`Runtime.Fixtures`](../src/MF2/Runtime/Fixtures.idr).

## Specifications

- [Formatting](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#formatting)
- [Option resolution](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#option-resolution)
- [Function handler](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#function-handler)
