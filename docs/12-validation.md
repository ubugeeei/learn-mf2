# Semantic validation と type refinement

parser が成功しても message は invalid かもしれません。validator は data-model error を列挙し、成功時にだけ dependent IR を構築します。

## validation pass

1. expression/markup ごとの duplicate option を検出。
2. declaration の bound/reference history を検査。
3. direct/indirect function annotation environment を構築。
4. variant key arity を検査。
5. all-catchall fallback を探索。
6. normalized key list の重複を検査。
7. `List` を exact-size `Vect` に変換。
8. `AllCatchall` witness を構築。

## error accumulation

`Validation value = Either (List Diagnostic) value` とし、独立して報告できる error をまとめます。arity が不正なまま dependent conversion を強行せず、error が空の場合のみ `exactVect` を呼ぶ構成です。

## indirect annotation

function のない local variable でも、operand が annotated declaration を参照すれば selector に使えます。`annotationEnvironment` は declaration order で annotation を伝播します。forward reference は先に duplicate-declaration で拒否されるため循環しません。

## proof construction

`proveAllCatchall` は `Vect n Key` を走査し、すべて Catchall のときだけ `AllCatchall keys` を返します。boolean check と proof construction を同じ traversal に閉じ込めています。

## 対応実装

- [`validate`](../src/MF2/Validate.idr)
- [`compileMatch`](../src/MF2/Validate.idr)
- [`proveAllCatchall`](../src/MF2/Validate.idr)
- [`CompiledMessage`](../src/MF2/IR.idr)

## 仕様

- [Well-formed vs valid](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#well-formed-vs-valid-messages)
- [Data model errors](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#data-model-errors)
- [Interchange data model](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#interchange-data-model)

