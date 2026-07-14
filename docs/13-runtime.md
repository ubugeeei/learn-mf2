# Runtime, resolution, and extensions

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

## Corresponding implementation

- [`ResolvedValue`](../src/MF2/Runtime/Types.idr)
- [`resolveExpression`](../src/MF2/Runtime/Resolution.idr)
- [`selectPattern`](../src/MF2/Runtime/Resolution.idr)
- [`formatToParts`](../src/MF2/Runtime/Format.idr)
- [`formatToString`](../src/MF2/Runtime/Format.idr)

## Specifications

- [Formatting](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#formatting)
- [Option resolution](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#option-resolution)
- [Function handler](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#function-handler)
