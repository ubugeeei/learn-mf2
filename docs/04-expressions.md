# Expressions, literals, variables, options, and attributes

An expression appears inside `{...}`. There are three forms, determined by the operand and the presence of a function annotation.

```mf2
{horse}
{$name}
{:app:now}
{$n :number select=exact}
```

## Operands

A literal without a function is always a string. `{42}` is the text `42`, not a number. Write `{42 :number}` to resolve it as a number.

A variable is referenced as `$name`. If it has no declaration, resolution looks for an implicit input in the formatting context. If it is absent, the result is an unresolved-variable error with the fallback output `{$name}`.

## Functions and namespaces

A function is introduced by a `:identifier` annotation. Default functions have no namespace. Application-defined functions should use a namespace, such as `:app:name`.

## Options

An option is written `name=value`, where the value is a literal or variable. Option order has no meaning, and duplicate option names are compile-time data-model errors.

```mf2
{$amount :currency currency=USD currencyDisplay=code}
```

## Attributes

Attributes are preserved for tooling and output metadata; they are not options passed to a function handler: `{$name @source=profile @important}`.

[`Expression`](../src/MF2/Syntax.idr) separates `operand : Maybe Operand` from `function : Maybe FunctionRef`, while [`OutputPart`](../src/MF2/Runtime/Format.idr) retains attributes in structured output.

## Corresponding implementation

- [`parseExpression`](../src/MF2/Parser/Expression.idr)
- [`parseFunction`](../src/MF2/Parser/Expression.idr)
- [`resolveExpression`](../src/MF2/Runtime/Resolution.idr)
- [`Expression`](../src/MF2/Syntax.idr)

## Specifications

- [Expressions](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#expressions)
- [Options](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#options)
- [Attributes](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#attributes)
- [Expression resolution](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#expression-resolution)
