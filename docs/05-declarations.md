# Declaration と call-by-need

## `.input`

input declaration は external input を message 内へ明示し、必要なら function を一度適用します。

```mf2
.input {$count :number}
```

## `.local`

local declaration は expression の resolved value を新しい名前へ束縛します。

```mf2
.local $price = {$raw :currency currency=JPY}
{{Price: {$price}}}
```

## 再宣言と implicit declaration

declaration は shadowing 可能な `let` ではありません。以前の declaration 内で external variable として参照した名前を後から宣言することも duplicate-declaration です。self-reference も同じ error になります。

```mf2
.local $a = {$future}
.local $future = {42}
{{invalid}}
```

validator は bound name だけでなく、それまでに現れた variable reference を追跡します。input declaration の自分自身の operand は binding の定義なので例外ですが、その function option で自分を参照することはできません。

## 一度だけ評価

function handler は mutable clock 等を読む可能性があるため、同じ declaration を複数回評価してはいけません。runtime は declaration を source order で一度だけ解決し、`ResolvedEnv` に保存します。これは eager ですが「at most once」を満たし、call-by-name にはなりません。

indirect selector annotation も伝播します。

```mf2
.input {$a :string}
.local $b = {$a}
.match $b
x {{yes}}
* {{no}}
```

## 対応実装

- [`Declaration`](../src/MF2/Syntax.idr)
- [`declarationErrors`](../src/MF2/Validate.idr)
- [`annotationEnvironment`](../src/MF2/Validate.idr)
- [`evaluateDeclarations`](../src/MF2/Runtime.idr)

## 仕様

- [Declarations](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#declarations)
- [Formatting context](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#formatting-context)
- [Resolved values](https://www.unicode.org/reports/tr35/tr35-78/tr35-messageFormat.html#resolved-values)

