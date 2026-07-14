# learn-mf2

Unicode MessageFormat 2（MF2）を、仕様を読むだけでなく、Idris 2 でコンパイラを実装しながら完全に理解するためのリポジトリです。対象仕様は公開済みの **Unicode LDML Part 9, Version 48.2** に固定しています。

この実装は Idris を「構文が少し珍しい関数型言語」としては使いません。パース前の入力、well-formed な AST、valid なコンパイル済み IR を別の型にし、matcher の arity を `Vect` に持たせ、fallback がすべて `*` である証明を実行時から消去します。`--total` も全モジュールで強制します。

## すぐ試す

```console
$ nix develop
$ make check
$ ./build/exec/mf2 check 'Hello, {$name}!'
valid
$ ./build/exec/mf2 format 'Hello, {$name}!' name=World
Hello, World!
$ ./build/exec/mf2 format \
  '.input {$n :number} .match $n one {{one item}} * {{{$n} items}}' \
  n=2
2 items
```

`make check` はビルド、全テスト、Idris API documentation 生成を行います。テストには Unicode Working Group の `LDML48.2` snapshot から、syntax 114 件、syntax-error 133 件、data-model 23 件、runtime 40 件を取り込んでいます。生成系を含む現在の総 assertion 数はテスト出力を正としてください。

## 学習順

最初は [学習ロードマップ](docs/00-learning-path.md) から始めてください。仕様と実装を往復する順序を固定してあります。

1. [なぜ MF2 が必要か](docs/01-why-mf2.md)
2. [環境構築と最初の実行](docs/02-environment.md)
3. [メッセージ、pattern、escape](docs/03-patterns.md)
4. [expression、literal、variable](docs/04-expressions.md)
5. [declaration と評価](docs/05-declarations.md)
6. [matcher と variant selection](docs/06-matchers.md)
7. [エラー体系](docs/07-errors.md)
8. [default functions](docs/08-functions.md)
9. [markup、attribute、bidi](docs/09-markup-bidi.md)
10. [Idris による型設計](docs/10-idris-design.md)
11. [total parser](docs/11-parser.md)
12. [semantic validation](docs/12-validation.md)
13. [runtime と extension](docs/13-runtime.md)
14. [テスト戦略](docs/14-testing.md)
15. [セキュリティと実運用境界](docs/15-production.md)
16. [仕様書の読み方](docs/16-spec-reading-guide.md)
17. [CLDR 49 draft との差分](docs/17-draft-49.md)

参照した規格・仕様・公式 fixture は [仕様リンク総覧](docs/appendices/spec-index.md) に一つ残らずまとめています。実装済み範囲と意図的な境界は [conformance matrix](docs/appendices/conformance-matrix.md) を確認してください。

## 実装の入口

- [`MF2.Parser`](src/MF2/Parser.idr): fuel により全域性を証明する recursive-descent parser
- [`MF2.Syntax`](src/MF2/Syntax.idr): well-formed だが未検証の data model
- [`MF2.Validate`](src/MF2/Validate.idr): data-model error の蓄積と型の refinement
- [`MF2.IR`](src/MF2/IR.idr): `Vect (S n)`、`AllCatchall`、erased proof を持つ IR
- [`MF2.Decimal`](src/MF2/Decimal.idr): arbitrary-precision decimal
- [`MF2.Runtime`](src/MF2/Runtime.idr): resolution、selection、fallback、structured output、bidi
- [`MF2.Compiler`](src/MF2/Compiler.idr): 公開 compile/format API
- [`Main`](src/Main.idr): CLI
- [`TestMain`](tests/TestMain.idr): property table と公式 fixture runner
- [`TypeLevel`](tests/TypeLevel.idr): コンパイルそのものがテストになる型レベル例

## 重要なスコープ

compiler front-end（syntax、data-model validation、型付き matcher IR）は LDML 48.2 の公式 fixture を基準にしています。runtime は仕様アルゴリズムを学べる依存ゼロの reference backend で、全 default function 名を受理しますが、CLDR locale data 全量を同梱していません。そのため、全 locale の数値・通貨・単位・日時の表示を production 品質で行う部分は handler 境界から ICU 等へ接続する設計です。この差は「未記載の制限」にせず、[conformance matrix](docs/appendices/conformance-matrix.md) に項目単位で明示しています。

## License

プロジェクト本体は MIT License です。Unicode 公式 fixture 由来のデータには [`tests/LICENSE.unicode`](tests/LICENSE.unicode) が適用されます。由来は [`tests/NOTICE.md`](tests/NOTICE.md) に固定しています。

