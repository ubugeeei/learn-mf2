module Support.SemanticCases

import MF2.Compiler
import MF2.Diagnostic
import MF2.IR
import Support.Results

%default total

public export
record SemanticCase where
  constructor MkSemanticCase
  source : String
  expected : ErrorKind

public export
semanticCases : List SemanticCase
semanticCases =
  [ MkSemanticCase ".input {$x} .match $x one {{one}} * {{other}}" MissingSelectorAnnotation
  , MkSemanticCase ".input {$x :string} .match $x one {{one}}" MissingFallbackVariant
  , MkSemanticCase ".input {$x :string} .match $x * * {{bad}}" VariantKeyMismatch
  , MkSemanticCase ".input {$x} .input {$x} {{bad}}" DuplicateDeclaration
  , MkSemanticCase "{x :f a=1 a=2}" DuplicateOptionName
  , MkSemanticCase ".input {$x :string} .match $x * {{a}} * {{b}}" DuplicateVariant
  ]

public export
runSemanticCases : List SemanticCase -> Results
runSemanticCases [] = empty
runSemanticCases (test :: rest) =
  let current = case compile test.source of
        Left (ValidationFailure diagnostics) => check
          ("missing semantic diagnostic " ++ show test.expected ++ " for " ++ test.source)
          (any (\diagnostic => diagnostic.kind == test.expected) diagnostics)
        _ => failure ("semantic case unexpectedly compiled: " ++ test.source) in
      combine current (runSemanticCases rest)
