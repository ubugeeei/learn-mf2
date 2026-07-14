# Error taxonomy と fallback

MF2 の error は発見フェーズが違います。

| class | 例 | この実装の型 |
|---|---|---|
| Syntax Error | brace 不足、不正 escape | `ParseFailure Diagnostic` |
| Data Model Error | key arity、fallback、重複 | `ValidationFailure (List Diagnostic)` |
| Resolution Error | unresolved variable、unknown function | `FormatResult.errors` |
| Message Function Error | bad operand/option/key | `FormatResult.errors` |

## syntax と data model を分ける

`.input {$x} .match $x one {{one}} * {{other}}` は grammar には合います。しかし selector annotation がなく invalid です。parser がこれを拒否すると tooling は「syntax が壊れた」のか「意味制約に違反した」のかを区別できません。

## error accumulation

parser は最初の構文エラーで停止します。validator は独立した data-model error を可能な限り蓄積します。runtime も fallback output と diagnostics を同時に返します。

## fallback representation

- unresolved `$name` は `{$name}`
- literal operand の function failure は `{|literal|}`
- operand なし function は `{:namespace:name}`
- fallback を local variable で参照し直すと、その variable 名の `{$local}` になる

valid message は runtime error があっても formatted result を得られなければなりません。

## 対応実装

- [`ErrorKind`](../src/MF2/Diagnostic.idr)
- [`CompileError`](../src/MF2/Compiler.idr)
- [`validate`](../src/MF2/Validate.idr)
- [`fallbackSource`](../src/MF2/Runtime.idr)

## 仕様

- [Errors](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#errors)
- [Fallback resolution](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#fallback-resolution)
- [Formatting fallback values](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#formatting-fallback-values)

