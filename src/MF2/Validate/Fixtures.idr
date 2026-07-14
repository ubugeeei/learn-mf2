module MF2.Validate.Fixtures

%default total

||| A source string paired with its first expected data-model error category.
public export
record ErrorFixture where
  constructor MkErrorFixture
  description : String
  source : String
  expected : String

||| 23 semantic-error cases from test/tests/data-model-errors.json.
public export
dataModelErrors : List ErrorFixture
dataModelErrors = [
  MkErrorFixture "(official fixture)" ".input {$foo :x} .match $foo * * {{foo}}" "variant-key-mismatch",
  MkErrorFixture "(official fixture)" ".input {$foo :x} .input {$bar :x} .match $foo $bar * {{foo}}" "variant-key-mismatch",
  MkErrorFixture "(official fixture)" ".input {$foo :x} .match $foo 1 {{_}}" "missing-fallback-variant",
  MkErrorFixture "(official fixture)" ".input {$foo :x} .match $foo other {{_}}" "missing-fallback-variant",
  MkErrorFixture "(official fixture)" ".input {$foo :x} .input {$bar :x} .match $foo $bar * 1 {{_}} 1 * {{_}}" "missing-fallback-variant",
  MkErrorFixture "(official fixture)" ".input {$foo} .match $foo one {{one}} * {{other}}" "missing-selector-annotation",
  MkErrorFixture "(official fixture)" ".local $foo = {$bar} .match $foo one {{one}} * {{other}}" "missing-selector-annotation",
  MkErrorFixture "(official fixture)" ".input {$bar} .local $foo = {$bar} .match $foo one {{one}} * {{other}}" "missing-selector-annotation",
  MkErrorFixture "(official fixture)" ".input {$foo} .input {$foo} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" ".input {$foo} .local $foo = {42} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" ".local $foo = {42} .input {$foo} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" ".local $foo = {:unknown} .local $foo = {42} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" ".local $foo = {$bar} .local $bar = {42} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" ".local $foo = {$foo} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" ".local $foo = {$bar} .local $bar = {$baz} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" ".local $foo = {$bar :func} .local $bar = {$baz} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" ".local $foo = {42 :func opt=$foo} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" ".local $foo = {42 :func opt=$bar} .local $bar = {42} {{_}}" "duplicate-declaration",
  MkErrorFixture "(official fixture)" "bad {:placeholder option=x option=x}" "duplicate-option-name",
  MkErrorFixture "(official fixture)" "bad {:placeholder ns:option=x ns:option=y}" "duplicate-option-name",
  MkErrorFixture "(official fixture)" ".input {$var :string} .match $var * {{The first default}} * {{The second default}}" "duplicate-variant",
  MkErrorFixture "(official fixture)" ".input {$x :string} .input {$y :string} .match $x $y * foo {{The first foo variant}} bar * {{The bar variant}} * |foo| {{The second foo variant}} * * {{The default variant}}" "duplicate-variant",
  MkErrorFixture "(official fixture)" ".local $star = {star :string} .match $star |*| {{Literal star}} * {{The default}}" "data-model-error"
  ]
