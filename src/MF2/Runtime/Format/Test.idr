module MF2.Runtime.Format.Test

import MF2.Compiler
import MF2.Decimal
import MF2.Diagnostic
import MF2.IR
import MF2.Runtime
import MF2.Syntax
import MF2.Testing

%default total

record FormatCase where
  constructor MkFormatCase
  label : String
  source : String
  inputs : List (String, Value)
  locale : String
  expected : String

formatCases : List FormatCase
formatCases =
  [ MkFormatCase "plain text" "hello" [] "en" "hello"
  , MkFormatCase "variable" "Hello, {$name}!" [("name", StringValue "Ada")] "en" "Hello, Ada!"
  , MkFormatCase "literal" "Value: {|a b|}" [] "en" "Value: a b"
  , MkFormatCase "escape" "\\{x\\}" [] "en" "{x}"
  , MkFormatCase "markup is empty in strings" "a{#b}b{/b}c" [] "en" "abc"
  , MkFormatCase "number" "{12.50 :number}" [] "en" "12.5"
  , MkFormatCase "negative number" "{-0.125 :number}" [] "en" "-0.125"
  , MkFormatCase "integer truncation" "{-12.9 :integer}" [] "en" "-12"
  , MkFormatCase "offset add" "{1 :offset add=2}" [] "en" "3"
  , MkFormatCase "offset subtract" "{3 :offset subtract=2}" [] "en" "1"
  , MkFormatCase "percent" "{0.25 :percent}" [] "en" "25%"
  , MkFormatCase "currency" "{12 :currency currency=USD}" [] "en" "USD 12"
  , MkFormatCase "unit" "{12 :unit unit=meter}" [] "en" "12 meter"
  , MkFormatCase "date" "{|2026-07-14| :date}" [] "en" "2026-07-14"
  , MkFormatCase "time" "{|12:30| :time}" [] "en" "12:30"
  , MkFormatCase "datetime" "{|2026-07-14T12:30| :datetime}" [] "en" "2026-07-14T12:30"
  , MkFormatCase "fallback variable" "{$missing}" [] "en" "{$missing}"
  , MkFormatCase "fallback function" "{:example:missing}" [] "en" "{:example:missing}"
  , MkFormatCase "fallback literal function" "{42 :example:missing}" [] "en" "{|42|}"
  , MkFormatCase "exact selector"
      ".input {$n :number} .match $n 1 {{exact}} one {{plural}} * {{other}}"
      [("n", NumberValue (MkDecimal 1 0))] "en" "exact"
  , MkFormatCase "English plural"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 1 0))] "en" "one"
  , MkFormatCase "English plural fallback"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 2 0))] "en" "other"
  , MkFormatCase "French zero plural"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 0 0))] "fr" "one"
  , MkFormatCase "Japanese plural"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 1 0))] "ja" "other"
  , MkFormatCase "ordinal"
      ".input {$n :number select=ordinal} .match $n two {{second}} * {{other}}"
      [("n", NumberValue (MkDecimal 2 0))] "en" "second"
  , MkFormatCase "ordinal teen exception"
      ".input {$n :number select=ordinal} .match $n two {{second}} * {{other}}"
      [("n", NumberValue (MkDecimal 12 0))] "en" "other"
  , MkFormatCase "two selectors"
      ".input {$a :string} .input {$b :string} .match $a $b x y {{both}} x * {{first}} * * {{none}}"
      [("a", StringValue "x"), ("b", StringValue "y")] "en" "both"
  , MkFormatCase "first selector preference"
      ".input {$a :string} .input {$b :string} .match $a $b x * {{first}} * y {{second}} * * {{none}}"
      [("a", StringValue "x"), ("b", StringValue "y")] "en" "first"
  , MkFormatCase "indirect selector annotation"
      ".input {$a :string} .local $b = {$a} .match $b x {{yes}} * {{no}}"
      [("a", StringValue "x")] "en" "yes"
  , MkFormatCase "local value reuse"
      ".local $x = {42 :number} {{{$x} and {$x}}}" [] "en" "42 and 42"
  , MkFormatCase "local fallback uses local name"
      ".local $x = {$missing} {{{$x}}}" [] "en" "{$x}"
  ]

runFormatCases : List FormatCase -> Results
runFormatCases [] = empty
runFormatCases (test :: rest) =
  let context = MkContext test.locale LTR test.inputs [] False
      current = case format context test.source of
        Left error => failure ("runtime case did not compile: " ++ test.label ++ "\n  " ++ show error)
        Right (actual, errors) => check
          ("runtime mismatch: " ++ test.label ++ "\n  expected: " ++ test.expected
            ++ "\n  actual: " ++ actual ++ "\n  errors: " ++ show errors)
          (actual == test.expected) in
      combine current (runFormatCases rest)

hasMarkup : List OutputPart -> Bool
hasMarkup [] = False
hasMarkup (MarkupOutput _ _ _ _ :: rest) = True
hasMarkup (_ :: rest) = hasMarkup rest

structuredMarkup : Bool
structuredMarkup = case compile "a{#strong}b{/strong}c" of
  Left _ => False
  Right message => hasMarkup (formatToParts (defaultContext []) message).parts

||| End-to-end formatting cases plus an assertion that markup survives in the
||| structured API even though the string convenience API omits it.
public export
formatTests : Results
formatTests = combine (runFormatCases formatCases)
  (check "structured output retains markup" structuredMarkup)
