# テスト戦略

## 三層で壊す

1. compile-time proof: 型が合わない IR を作れないこと。
2. official conformance fixtures: Unicode WG と解釈を揃えること。
3. generated/handwritten cases: decimal、runtime、regression を広く叩くこと。

## compile-time tests

[`TypeLevel`](../tests/TypeLevel.idr) は二 selector plan と二 key variant、all-catchall proof を組み立てます。`Vect` の長さを変えると test executable を起動する前に typecheck が失敗します。

## official snapshot

fixture は mutable `main` branch ではなく `LDML48.2` tag と commit `7f142fb4f1f5ea6ab1eb34ce2b87e918ca9fd331` に固定しています。

| upstream suite | local assertions |
|---|---:|
| `syntax.json` | 114 |
| `syntax-errors.json` | 133 |
| `data-model-errors.json` | 23 |
| `fallback.json` | 8 |
| `pattern-selection.json` | 22 |
| `u-options.json` | 10 |

fixture の license と provenance は [`NOTICE`](../tests/NOTICE.md) を参照してください。

## generated decimal tests

正負 integer の広い範囲を生成し `parseDecimal` と `renderDecimal` の round-trip を検査します。fraction、exponent、leading zero、empty fraction、truncate toward zero も独立ケースがあります。

## regression table

markup、fallback、全 default function、English/Japanese plural、ordinal、複数 selector、indirect annotation を table-driven test にしています。

## 実行

```console
$ make test
$ make check
$ nix flake check --print-build-logs
```

test count を文書に固定値として信じず、最終出力の `N passed; 0 failed` を証拠にします。

## 仕様

- [Unicode MF2 test suite](https://github.com/unicode-org/message-format-wg/tree/LDML48.2/test)
- [test schema](https://github.com/unicode-org/message-format-wg/blob/LDML48.2/test/schemas/v0/tests.schema.json)
- [Unicode License](https://www.unicode.org/license.txt)

