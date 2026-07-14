# 仕様書の読み方

## version を固定する

最初に header の version と status を確認します。このコースの normative baseline は [LDML Part 9 Version 48.2](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html) です。Working Group repository では [`LDML48.2` tag](https://github.com/unicode-org/message-format-wg/tree/LDML48.2) を使います。

unversioned URL や `main` branch は将来内容が変わるため、fixture や conformance claim の根拠にはしません。

## 推奨順序

1. Introduction の terminology と stability policy。
2. Syntax 全体を読み、最後に ABNF と照合。
3. Formatting の resolved value と fallback。
4. Pattern selection algorithm を擬似実行。
5. Errors で phase boundary を確認。
6. Default functions は string、number、date/time の順。
7. Unicode namespace と bidi。
8. Interchange data model。
9. Security considerations。

## normative と non-normative

example は理解に有用ですが normative ではありません。MUST/SHOULD/MAY は BCP 14 の意味で使われます。実装判断では prose の要件、ABNF、error definition、test fixture を突き合わせます。

## spec と test がずれたら

1. 同じ release tag か確認。
2. fixture schema の optional/draft tag を確認。
3. implementation-dependent output か確認。
4. specification issue/corrigendum を探す。
5. 推測で fixture を書き換えず、最小 reproduction を残す。

## 全リンク

このリポジトリで参照する normative/non-normative source は [仕様リンク総覧](appendices/spec-index.md) に集約しています。

