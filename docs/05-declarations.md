# Declarations and call-by-need

## `.input`

An input declaration makes an external input explicit within the message and may apply a function once.

```mf2
.input {$count :number}
```

## `.local`

A local declaration binds an expression's resolved value to a new name.

```mf2
.local $price = {$raw :currency currency=JPY}
{{Price: {$price}}}
```

## Redeclaration and implicit declarations

Declarations are not shadowable `let` bindings. A name previously referenced as an external variable cannot be declared later: doing so is a duplicate-declaration error. Self-reference produces the same error.

```mf2
.local $a = {$future}
.local $future = {42}
{{invalid}}
```

The validator tracks both bound names and all variable references encountered so far. The input declaration's own operand is an exception because it defines the binding, but the declaration cannot refer to itself from one of its function options.

## Evaluate at most once

A function handler may read a mutable clock or another changing resource, so a declaration must not be evaluated repeatedly. The runtime resolves declarations exactly once in source order and stores each result in `ResolvedEnv`. This strategy is eager, but it satisfies “at most once” and is not call-by-name.

Indirect selector annotations are propagated as well.

```mf2
.input {$a :string}
.local $b = {$a}
.match $b
x {{yes}}
* {{no}}
```

## Corresponding implementation

- [`Declaration`](../src/MF2/Syntax.idr)
- [`declarationErrors`](../src/MF2/Validate.idr)
- [`annotationEnvironment`](../src/MF2/Validate.idr)
- [`evaluateDeclarations`](../src/MF2/Runtime/Resolution.idr)

## Specifications

- [Declarations](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#declarations)
- [Formatting context](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#formatting-context)
- [Resolved values](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#resolved-values)
