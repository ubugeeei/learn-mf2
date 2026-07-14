# 環境構築と最初の実行

## Nix shell

Idris 2 の version drift を避けるため、環境は [`flake.nix`](../flake.nix) で固定します。

```console
$ nix develop
$ idris2 --version
$ make build
$ make test
```

開発時の正規コマンドは次の通りです。

| command | 内容 |
|---|---|
| `make build` | `mf2` executable を生成 |
| `make typecheck` | code generation なしで全 module を検査 |
| `make test` | compiler を build 後、全 test を実行 |
| `make docs` | `|||` documentation comment から HTML を生成 |
| `make check` | 上記の release gate |
| `nix flake check` | isolated Nix build で test |

## CLI

```console
$ ./build/exec/mf2 check '.input {$n :number} .match $n one {{one}} * {{other}}'
valid
$ ./build/exec/mf2 format 'Hello, {$name}!' name=Ada
Hello, Ada!
```

CLI は `name=value` が MF2 `number-literal` に一致すれば exact decimal、それ以外は string として渡します。アプリケーション API では [`Value`](../src/MF2/Runtime.idr) を直接構築でき、date/time/unit/currency も型で渡せます。

## IDE と documentation

LSP を使う場合も `nix develop` 内から起動してください。公開 API の説明はすべて Idris の `|||` comment に置き、本文と同じ設計根拠を API documentation から読めるようにしています。

## 対応実装

- [`flake.nix`](../flake.nix)
- [`Makefile`](../Makefile)
- [`mf2.ipkg`](../mf2.ipkg)
- [`Main`](../src/Main.idr)
- [GitHub Actions](../.github/workflows/ci.yml)

