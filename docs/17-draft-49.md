# CLDR 49 draft との差分

2026-07-14 時点で、公開済み安定版は 48.2、次の 49 は proposed/draft です。この実装の parser と fixture は 48.2 に固定し、draft を暗黙に混ぜません。

draft 49 の MessageFormat modification には次が含まれます。

- 名称を “Unicode MessageFormat” へ変更。
- syntax/data-model error の優先を明確化。
- Default Bidi Strategy を required/default に変更。
- `:offset` の stable 化。
- `:datetime`、`:date`、`:time` を semantic skeleton 上へ更新。
- `:percent` を draft function として追加・整理。
- pattern selection 説明の refactor。

48.2 にもこれらの function 名や bidi algorithm は存在しますが、status と詳細要件が変わる点に注意してください。「名前が同じだから同じ仕様」とは限りません。

## upgrade 手順

1. `LDML49` の確定 tag を待つ。
2. `spec/message.abnf` を diff。
3. error priority と default function status/options を diff。
4. official fixture を別 module として追加し、48.2 suite を消さず両方実行。
5. IR 変更が backward-compatible か typecheck。
6. conformance matrix と docs の baseline 表示を更新。

## 参照

- [CLDR 49 proposed Part 9](https://www.unicode.org/reports/tr35/tr35-79/tr35-messageFormat.html)
- [CLDR 49 modifications](https://www.unicode.org/reports/tr35/tr35-79/tr35-modifications.html#messageformat)
- [CLDR 48.2 modifications](https://www.unicode.org/reports/tr35/tr35-78/tr35-modifications.html)
- [Working Group main](https://github.com/unicode-org/message-format-wg)

