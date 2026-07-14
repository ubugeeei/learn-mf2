# Markup、attribute、structured output、bidi

## markup は HTML ではない

```mf2
This is {#emphasis}important{/emphasis}.
Icon: {#icon name=warning /}
```

MF2 は open、close、standalone を表しますが、nesting や tag name の対応を要求しません。意味は application が決めます。string target では markup の default representation は空文字です。

[`OutputPart`](../src/MF2/Runtime.idr) は markup を構造のまま返します。これを HTML source に直結させず、許可済み component table へ mapping するのが安全です。

## `u:id`

`u:id` は structured part の識別子です。string output では無視されます。二つの同じ placeholder を UI 上で区別する用途があります。

## `u:dir` と default bidi strategy

direction は `ltr`、`rtl`、`auto`、`inherit`。plain string では expression の方向と message direction に応じ、LRI U+2066、RLI U+2067、FSI U+2068、PDI U+2069 を挿入します。

```mf2
hello {world :string u:dir=rtl}
```

表示上は見えにくい control character ですが、RTL/LTR 混在時の spillover を防ぎます。runtime は formatted text を覗いて direction を推測せず、`ResolvedValue.direction` を handler から受け取ります。

## 対応実装

- [`Markup`](../src/MF2/Syntax.idr)
- [`MarkupOutput`](../src/MF2/Runtime.idr)
- [`isolateText`](../src/MF2/Runtime.idr)
- [公式 u-options fixtures](../tests/OfficialRuntimeFixtures.idr)

## 仕様

- [Markup](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#markup)
- [Unicode namespace](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#unicode-namespace)
- [Handling bidirectional text](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#handling-bidirectional-text)
- [Unicode Bidirectional Algorithm, UAX #9](https://www.unicode.org/reports/tr9/)

