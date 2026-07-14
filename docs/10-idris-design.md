# Idris のポテンシャルを使い切る設計

## phase を型で分ける

untrusted source は [`parse`](../src/MF2/Parser.idr) で `RawMessage` になります。この時点で grammar は満たしますが、data-model constraint は未検証です。次の [`validate`](../src/MF2/Validate.idr) だけが `CompiledMessage` を生成します。

```text
String --parse--> RawMessage --validate--> CompiledMessage
```

一つの巨大な AST に `isValid : Bool` を付ける設計では、formatter が毎回その bool を信頼する必要があります。型を分ければ、formatter の引数に raw state が到達しません。

## arity を index にする

`Variant n` は `Vect n Key` を持ちます。`MatchPlan tail` の selector は `Vect (S tail) Selector` です。したがって次は compile しません。

```idris
-- 2 selectors に 1 key の variant を渡すため type mismatch
bad : MatchPlan 1
```

この negative example を test で実行する必要はありません。コンパイラが test runner より前に拒否します。positive witness は [`TypeLevel`](../tests/TypeLevel.idr) にあります。

## proposition と erased proof

fallback の key が全部 `Catchall` であることを proposition にします。

```idris
data AllCatchall : Vect arity Key -> Type where
  EmptyCatchall : AllCatchall []
  NextCatchall : AllCatchall rest -> AllCatchall (Catchall :: rest)
```

`FallbackVariant` の proof field は `0` multiplicity なので runtime representation から消えます。保証は強く、実行時コストはゼロです。

## totality

package は `--total` で build します。parser は mutually recursive grammar を fuel で構造的再帰に変換し、decimal normalization は scale に対して再帰します。partial function や unchecked index access は formatter path にありません。

## dependent pair を隠す existential body

message を読み込む時点では matcher arity は runtime value です。`Dynamic : (tail : Nat) -> MatchPlan tail -> CompiledBody` が arity と、それに依存する plan を同じ constructor に package します。

## 設計上あえて型にしなかったもの

locale、function registry、external input の有無は runtime context です。ここまで compile-time type に押し込むと、翻訳資産の dynamic loading や plugin handler が使いにくくなります。Idris の力は「すべてを型にする」ことではなく、静的に決められる invariant を正しい境界で型に移すことに使います。

## 対応実装

- [`IR`](../src/MF2/IR.idr)
- [`Validate`](../src/MF2/Validate.idr)
- [`Decimal`](../src/MF2/Decimal.idr)
- [`TypeLevel`](../tests/TypeLevel.idr)

