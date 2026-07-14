# Glossary

| term | 意味 |
|---|---|
| message | 一回の formatting request を表す template 全体 |
| simple message | declaration/matcher を持たない pattern |
| complex message | declaration または matcher を持つ message |
| pattern | text/expression/markup part の列 |
| placeholder | `{...}` で囲まれた expression または markup |
| operand | expression が function へ渡す literal/variable |
| annotation | `:number` 等の function reference |
| external variable | Context の input mapping から得る値 |
| local variable | `.local` が作る resolved value |
| selector | matcher が variant 選択に使う annotated variable |
| variant | key vector と quoted pattern の組 |
| catch-all | variant key の `*`。literal `|*|` とは異なる |
| well-formed | ABNF grammar を満たす状態 |
| valid | well-formed かつ data-model constraints を満たす状態 |
| resolved value | formatting/selection/direction 等の capability を持つ runtime value |
| fallback | resolution failure を表示可能にする代替 value |
| function handler | annotation を runtime value へ解決する application/default procedure |
| formatting context | locale、direction、inputs、registry 等 |
| bidi isolation | LTR/RTL spillover を防ぐ Unicode isolate controls |
| CLDR | locale data と rules を提供する Unicode project |
| arity | matcher の selector 数、すなわち各 variant の key 数 |
| refinement | raw data を検査し、より強い invariant の型へ変換すること |

