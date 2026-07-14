# Matcher と pattern selection

matcher は一つ以上の selector と、一つ以上の variant から成ります。

```mf2
.input {$count :number}
.match $count
0     {{none}}
one   {{one}}
*     {{many}}
```

## valid である条件

- selector は 1 個以上。
- 全 variant の key 数は selector 数と同じ。
- すべての key が `*` の fallback variant が最低一つある。
- selector は function annotation を持つ declaration を直接または間接に参照する。
- 同じ normalized key list の variant は重複できない。

quoted literal `|*|` は literal star であり catch-all `*` ではありません。

## selection の順序

各 selector は key に対する `Match` と `BetterThan` を提供します。概念上の優先度は exact numeric/string match、plural/ordinal rule match、catch-all の順です。複数 selector では source order で lexicographic に比較します。

## 型で保証する

raw parser は key 数不一致も表現できる [`RawVariant`](../src/MF2/Syntax.idr) を返します。validator 成功後は `selectors : Vect (S tail) Selector` と `variants : List (Variant (S tail))` を持つ [`MatchPlan`](../src/MF2/IR.idr) に変わります。

`S tail` により selector 0 個は表現不能です。fallback は [`AllCatchall`](../src/MF2/IR.idr) proof を持ちます。

## 対応実装

- [`parseVariants`](../src/MF2/Parser.idr)
- [`compileMatch`](../src/MF2/Validate.idr)
- [`selectBest`](../src/MF2/Runtime.idr)
- [`TypeLevel`](../tests/TypeLevel.idr)

## 仕様

- [Matcher](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#matcher)
- [Pattern selection](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#pattern-selection)
- [Pattern selection examples](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#pattern-selection-examples)
- [CLDR plural rules 48](https://unicode.org/cldr/charts/48/supplemental/language_plural_rules.html)

