# LDML 48.2 conformance matrix

この表は claim を過大にしないための実装境界です。`yes` は local tests と公式 fixture で継続検証、`reference` はアルゴリズム学習用の実装、`external` は production handler/data backend が必要、`not yet` は未実装です。

## Syntax と data model

| requirement | status | evidence |
|---|---|---|
| simple/complex message | yes | official syntax fixtures |
| declarations | yes | parser + duplicate declaration fixtures |
| quoted pattern/text/escape | yes | official syntax/error fixtures |
| expression/operand/function/options | yes | official syntax fixtures |
| markup/attributes | yes | official syntax + u-options fixtures |
| matcher/variants/keys | yes | official syntax + pattern-selection fixtures |
| identifier Unicode ranges | yes within Idris `Char` | parser character classes |
| host representation of unpaired surrogate | not representable | Idris scalar boundary |
| variant key arity | yes, type-refined | `Vect n Key` |
| all-catchall fallback | yes, proved | erased `AllCatchall` proof |
| selector annotation direct/indirect | yes | validator + fixtures |
| duplicate option/declaration/variant | yes | official data-model fixtures |

## Formatting

| requirement | status | note |
|---|---|---|
| formatting context/input mapping | yes | `Context` |
| literal/variable/function resolution | yes | official fallback fixtures |
| options as order-insensitive mapping | yes | resolved list after duplicate validation |
| declaration evaluation at most once | yes | eager, source-order memoization |
| fallback representations | yes | official fallback output fixtures |
| pattern selection | yes for supplied selection operations | official pattern-selection fixtures |
| string exact selection | yes | built-in handler |
| numeric exact selection | yes | arbitrary-precision decimal |
| all CLDR plural locales | external | reference includes en/fr/ja/zh/ko teaching rules |
| NormalizeKey NFC | external | Unicode normalization backend required |
| structured parts | yes | `OutputPart` |
| markup empty in string target | yes | runtime + fixtures |
| default bidi strategy | yes | official u-options output fixtures |

## Default functions

| function | accepted | full locale formatting |
|---|---:|---:|
| `:string` | yes | yes for string semantics |
| `:number` | yes | external for full CLDR options |
| `:integer` | yes | external for full CLDR options |
| `:offset` | yes | reference exact arithmetic |
| `:currency` | yes | external for symbols/patterns |
| `:percent` | yes | external for locale patterns |
| `:unit` (Draft in 48.2) | yes | external for conversion/preferences |
| `:datetime` | yes | external for calendars/skeletons/TZDB |
| `:date` | yes | external for calendars/skeletons/TZDB |
| `:time` | yes | external for calendars/skeletons/TZDB |

「accepted」は unknown-function にしないことを表し、すべての option が locale 固有の完成出力を生むという意味ではありません。unsupported combination を production backend が diagnostic にする余地があります。

## Interchange と tooling

| feature | status |
|---|---|
| internal data model | yes |
| JSON `message.json` import/export | not yet |
| XML representation | not yet |
| source-preserving concrete syntax tree | not yet |
| rich source locations for every token | partial: expression/declaration/variant/option |

## Test evidence

公式 `LDML48.2` snapshot 310 cases（syntax 114、syntax-error 133、data-model 23、runtime 40）に加え、generated decimal と regression tests を実行します。正確な総数は `make test` の出力を参照してください。
