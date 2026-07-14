# Glossary

| Term | Meaning |
|---|---|
| message | The complete template for one formatting request |
| simple message | A pattern with no declarations or matcher |
| complex message | A message containing declarations or a matcher |
| pattern | A sequence of text, expression, and markup parts |
| placeholder | An expression or markup node enclosed in `{...}` |
| operand | A literal or variable supplied by an expression to a function |
| annotation | A function reference such as `:number` |
| external variable | A value obtained from the context's input mapping |
| local variable | A resolved value created by `.local` |
| selector | An annotated variable a matcher uses to select a variant |
| variant | A key vector paired with a quoted pattern |
| catch-all | The variant key `*`, distinct from the literal `|*|` |
| well-formed | Satisfying the ABNF grammar |
| valid | Well-formed and satisfying all data-model constraints |
| resolved value | A runtime value with formatting, selection, direction, and related capabilities |
| fallback | A replacement value that keeps a resolution failure displayable |
| function handler | A default or application procedure that resolves an annotation into a runtime value |
| formatting context | The locale, direction, inputs, registry, and related runtime state |
| bidi isolation | Unicode isolate controls that prevent LTR/RTL spillover |
| CLDR | The Unicode project that supplies locale data and rules |
| arity | The matcher selector count, and therefore each variant's key count |
| refinement | Validating raw data into a type with stronger invariants |
