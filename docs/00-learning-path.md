# 学習ロードマップ

このコースのゴールは「MF2 の記法を使える」ではありません。次の問いに、仕様節と Idris の型を根拠に答えられる状態をゴールにします。

- simple message と complex message はどこで区別されるか。
- well-formed と valid はなぜ別のフェーズか。
- selector の annotation が必要なのはなぜか。
- fallback variant があるのに pattern selection が非自明なのはなぜか。
- resolution error 後も valid message が必ず出力を返せるのはなぜか。
- markup を文字列へ直接埋めないことが、なぜ安全性につながるか。
- locale data と message compiler の責務をどこで分けるべきか。
- Idris の依存型で何を静的保証し、何を実行時に残すべきか。

## フェーズ 1: 利用者として読む

[01](01-why-mf2.md) から [09](09-markup-bidi.md) までは MF2 の data model と runtime semantics を学びます。各章でサンプルを CLI に渡し、対応する specification anchor と実装へ進んでください。

完了条件:

- placeholder、expression、markup の違いを説明できる。
- `.input`、`.local`、`.match` を自力で書ける。
- exact key、plural key、`*` の優先順位を予測できる。
- syntax/data-model/resolution/function error を分類できる。

## フェーズ 2: コンパイラ作者として読む

[10](10-idris-design.md) から [13](13-runtime.md) は実装編です。`RawVariant` の key が `List Key` なのに、`Variant n` では `Vect n Key` になる理由が中心です。

完了条件:

- `parse : String -> Either Diagnostic RawMessage` と `validate : RawMessage -> Validation CompiledMessage` を分ける理由を説明できる。
- `MatchPlan tail` が selector 0 個を表現できないことを型から読める。
- `AllCatchall keys` の proof が runtime から erase される意味を説明できる。
- exact decimal に `Double` を使わない理由を説明できる。

## フェーズ 3: 適合性と実運用を判断する

[14](14-testing.md) から [17](17-draft-49.md) では、公式 fixture、セキュリティ、locale backend、draft drift を扱います。

完了条件:

- 「公式 fixture が通る」と「全 locale で完全適合」の違いを説明できる。
- NFC normalization、CLDR plural data、TZDB の責務を配置できる。
- 48.2 と draft 49 を混ぜずに upgrade plan を作れる。

## 推奨する手の動かし方

各章で次を繰り返します。

```console
$ nix develop
$ make test
$ ./build/exec/mf2 check '...'
$ ./build/exec/mf2 format '...' name=value
```

REPL で型を見る場合は `idris2 --repl mf2.ipkg` を使います。API documentation は `make docs` の後に `build/docs/mf2/index.html` へ生成されます。

## 仕様

- [LDML 48.2 Part 9](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html)
- [公式 Quick Start](https://messageformat.unicode.org/docs/quick-start/)
- [仕様リンク総覧](appendices/spec-index.md)

