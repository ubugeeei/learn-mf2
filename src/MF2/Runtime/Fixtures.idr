module MF2.Runtime.Fixtures

import MF2.Decimal
import MF2.Runtime

%default total

||| A runtime fixture from the Unicode LDML48.2 snapshot.
public export
record OfficialRuntime where
  constructor MkOfficialRuntime
  description : String
  source : String
  inputs : List (String, Value)
  locale : String
  direction : Direction
  bidi : Bool
  expected : String

||| Fallback, pattern-selection, and Unicode namespace fixtures.
public export
officialRuntime : List OfficialRuntime
officialRuntime = [
  MkOfficialRuntime "function with unquoted literal operand" "{42 :test:function fails=format}" [] "en-US" LTR False "{|42|}",
  MkOfficialRuntime "function with quoted literal operand" "{|C:\\\\| :test:function fails=format}" [] "en-US" LTR False "{|C:\\\\|}",
  MkOfficialRuntime "unannotated implicit input variable" "{$var}" [] "en-US" LTR False "{$var}",
  MkOfficialRuntime "annotated implicit input variable" "{$var :number}" [] "en-US" LTR False "{$var}",
  MkOfficialRuntime "local variable with unknown function in declaration" ".local $var = {|val| :test:undefined} {{{$var}}}" [] "en-US" LTR False "{$var}",
  MkOfficialRuntime "function with local variable operand with unknown function in declaration" ".local $var = {|val| :test:undefined} {{{$var :test:function}}}" [] "en-US" LTR False "{$var}",
  MkOfficialRuntime "local variable with unknown function in placeholder" ".local $var = {|val|} {{{$var :test:undefined}}}" [] "en-US" LTR False "{$var}",
  MkOfficialRuntime "function with no operand" "{:test:undefined}" [] "en-US" LTR False "{:test:undefined}",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select} .match $x 1.0 {{1.0}} 1 {{1}} * {{other}}" [] "und" LTR False "1",
  MkOfficialRuntime "Pattern selection" ".local $x = {0 :test:select} .match $x 1.0 {{1.0}} 1 {{1}} * {{other}}" [] "und" LTR False "other",
  MkOfficialRuntime "Pattern selection" ".input {$x :test:select} .match $x 1.0 {{1.0}} 1 {{1}} * {{other}}" [("x", NumberValue (MkDecimal 1 0))] "und" LTR False "1",
  MkOfficialRuntime "Pattern selection" ".input {$x :test:select} .match $x 1.0 {{1.0}} 1 {{1}} * {{other}}" [("x", NumberValue (MkDecimal 2 0))] "und" LTR False "other",
  MkOfficialRuntime "Pattern selection" ".input {$x :test:select} .local $y = {$x} .match $y 1.0 {{1.0}} 1 {{1}} * {{other}}" [("x", NumberValue (MkDecimal 1 0))] "und" LTR False "1",
  MkOfficialRuntime "Pattern selection" ".input {$x :test:select} .local $y = {$x} .match $y 1.0 {{1.0}} 1 {{1}} * {{other}}" [("x", NumberValue (MkDecimal 2 0))] "und" LTR False "other",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select decimalPlaces=1} .match $x 1.0 {{1.0}} 1 {{1}} * {{other}}" [] "und" LTR False "1.0",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select decimalPlaces=1} .match $x 1 {{1}} 1.0 {{1.0}} * {{other}}" [] "und" LTR False "1.0",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select decimalPlaces=9} .match $x 1.0 {{1.0}} 1 {{1}} * {{bad-option-value}}" [] "und" LTR False "bad-option-value",
  MkOfficialRuntime "Pattern selection" ".input {$x :test:select} .local $y = {$x :test:select decimalPlaces=1} .match $y 1.0 {{1.0}} 1 {{1}} * {{other}}" [("x", NumberValue (MkDecimal 1 0))] "und" LTR False "1.0",
  MkOfficialRuntime "Pattern selection" ".input {$x :test:select decimalPlaces=1} .local $y = {$x :test:select} .match $y 1.0 {{1.0}} 1 {{1}} * {{other}}" [("x", NumberValue (MkDecimal 1 0))] "und" LTR False "1.0",
  MkOfficialRuntime "Pattern selection" ".input {$x :test:select decimalPlaces=9} .local $y = {$x :test:select decimalPlaces=1} .match $y 1.0 {{1.0}} 1 {{1}} * {{bad-option-value}}" [("x", NumberValue (MkDecimal 1 0))] "und" LTR False "bad-option-value",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select fails=select} .match $x 1.0 {{1.0}} 1 {{1}} * {{other}}" [] "und" LTR False "other",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select fails=format} .match $x 1.0 {{1.0}} 1 {{1}} * {{other}}" [] "und" LTR False "1",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:format} .match $x 1.0 {{1.0}} 1 {{1}} * {{other}}" [] "und" LTR False "other",
  MkOfficialRuntime "Pattern selection" ".input {$x :test:select} .match $x 1.0 {{1.0}} 1 {{1}} * {{other}}" [] "und" LTR False "other",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select} .local $y = {1 :test:select} .match $x $y 1 1 {{1,1}} 1 * {{1,*}} * 1 {{*,1}} * * {{*,*}}" [] "und" LTR False "1,1",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select} .local $y = {0 :test:select} .match $x $y 1 1 {{1,1}} 1 * {{1,*}} * 1 {{*,1}} * * {{*,*}}" [] "und" LTR False "1,*",
  MkOfficialRuntime "Pattern selection" ".local $x = {0 :test:select} .local $y = {1 :test:select} .match $x $y 1 1 {{1,1}} 1 * {{1,*}} * 1 {{*,1}} * * {{*,*}}" [] "und" LTR False "*,1",
  MkOfficialRuntime "Pattern selection" ".local $x = {0 :test:select} .local $y = {0 :test:select} .match $x $y 1 1 {{1,1}} 1 * {{1,*}} * 1 {{*,1}} * * {{*,*}}" [] "und" LTR False "*,*",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select fails=select} .local $y = {1 :test:select} .match $x $y 1 1 {{1,1}} 1 * {{1,*}} * 1 {{*,1}} * * {{*,*}}" [] "und" LTR False "*,1",
  MkOfficialRuntime "Pattern selection" ".local $x = {1 :test:select} .local $y = {1 :test:format} .match $x $y 1 1 {{1,1}} 1 * {{1,*}} * 1 {{*,1}} * * {{*,*}}" [] "und" LTR False "1,*",
  MkOfficialRuntime "u: Options" "{#tag u:id=x}content{/ns:tag u:id=x}" [] "en-US" LTR True "content",
  MkOfficialRuntime "u: Options" "{#tag u:dir=rtl}content{/ns:tag}" [] "en-US" LTR True "content",
  MkOfficialRuntime "u: Options" "hello {world :string u:dir=ltr u:id=foo}" [] "en-US" LTR True "hello ⁦world⁩",
  MkOfficialRuntime "u: Options" "hello {world :string u:dir=rtl}" [] "en-US" LTR True "hello ⁧world⁩",
  MkOfficialRuntime "u: Options" "hello {world :string u:dir=auto}" [] "en-US" LTR True "hello ⁨world⁩",
  MkOfficialRuntime "u: Options" ".local $world = {world :string u:dir=ltr u:id=foo} {{hello {$world}}}" [] "en-US" LTR True "hello ⁦world⁩",
  MkOfficialRuntime "u: Options" "أهلاً {بالعالم :string u:dir=rtl}" [] "ar" RTL True "أهلاً ⁧بالعالم⁩",
  MkOfficialRuntime "u: Options" "أهلاً {بالعالم :string u:dir=auto}" [] "ar" RTL True "أهلاً ⁨بالعالم⁩",
  MkOfficialRuntime "u: Options" "أهلاً {world :string u:dir=ltr}" [] "ar" RTL True "أهلاً ⁦world⁩",
  MkOfficialRuntime "u: Options" "أهلاً {بالعالم :string}" [] "ar" RTL True "أهلاً ⁨بالعالم⁩"
  ]
