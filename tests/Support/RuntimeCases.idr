module Support.RuntimeCases

import MF2.Compiler
import MF2.Decimal
import MF2.Diagnostic
import MF2.Runtime
import MF2.Syntax
import Support.Results

%default total

public export
record FormatCase where
  constructor MkFormatCase
  label : String
  source : String
  inputs : List (String, Value)
  locale : String
  expected : String

public export
runtimeCases : List FormatCase
runtimeCases =
  [ MkFormatCase "plain text" "hello" [] "en" "hello"
  , MkFormatCase "variable" "Hello, {$name}!" [("name", StringValue "Ada")] "en" "Hello, Ada!"
  , MkFormatCase "literal" "Value: {|a b|}" [] "en" "Value: a b"
  , MkFormatCase "escape" "\\{x\\}" [] "en" "{x}"
  , MkFormatCase "markup is empty in strings" "a{#b}b{/b}c" [] "en" "abc"
  , MkFormatCase "number" "{12.50 :number}" [] "en" "12.5"
  , MkFormatCase "integer truncation" "{-12.9 :integer}" [] "en" "-12"
  , MkFormatCase "offset add" "{1 :offset add=2}" [] "en" "3"
  , MkFormatCase "offset subtract" "{3 :offset subtract=2}" [] "en" "1"
  , MkFormatCase "percent" "{0.25 :percent}" [] "en" "25%"
  , MkFormatCase "currency" "{12 :currency currency=USD}" [] "en" "USD 12"
  , MkFormatCase "unit" "{12 :unit unit=meter}" [] "en" "12 meter"
  , MkFormatCase "date" "{|2026-07-14| :date}" [] "en" "2026-07-14"
  , MkFormatCase "fallback variable" "{$missing}" [] "en" "{$missing}"
  , MkFormatCase "fallback function" "{:example:missing}" [] "en" "{:example:missing}"
  , MkFormatCase "exact selector"
      ".input {$n :number} .match $n 1 {{exact}} one {{plural}} * {{other}}"
      [("n", NumberValue (MkDecimal 1 0))] "en" "exact"
  , MkFormatCase "English plural"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 1 0))] "en" "one"
  , MkFormatCase "English plural fallback"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 2 0))] "en" "other"
  , MkFormatCase "Japanese plural"
      ".input {$n :number} .match $n one {{one}} * {{other}}"
      [("n", NumberValue (MkDecimal 1 0))] "ja" "other"
  , MkFormatCase "ordinal"
      ".input {$n :number select=ordinal} .match $n two {{second}} * {{other}}"
      [("n", NumberValue (MkDecimal 2 0))] "en" "second"
  , MkFormatCase "two selectors"
      ".input {$a :string} .input {$b :string} .match $a $b x y {{both}} x * {{first}} * * {{none}}"
      [("a", StringValue "x"), ("b", StringValue "y")] "en" "both"
  , MkFormatCase "indirect selector annotation"
      ".input {$a :string} .local $b = {$a} .match $b x {{yes}} * {{no}}"
      [("a", StringValue "x")] "en" "yes"
  ]

public export
runRuntimeCases : List FormatCase -> Results
runRuntimeCases [] = empty
runRuntimeCases (test :: rest) =
  let context = MkContext test.locale LTR test.inputs [] False
      current = case format context test.source of
        Left error => failure ("runtime case did not compile: " ++ test.label ++ "\n  " ++ show error)
        Right (actual, errors) => check
          ("runtime mismatch: " ++ test.label ++ "\n  expected: " ++ test.expected
            ++ "\n  actual: " ++ actual ++ "\n  errors: " ++ show errors)
          (actual == test.expected) in
      combine current (runRuntimeCases rest)
