module MF2.Validate.Test

import MF2.Compiler
import MF2.Diagnostic
import MF2.IR
import MF2.Testing
import MF2.Validate.Fixtures

%default total

hasKind : ErrorKind -> List Diagnostic -> Bool
hasKind expected = any (\diagnostic => diagnostic.kind == expected)

hasNamedKind : String -> List Diagnostic -> Bool
hasNamedKind expected = any (\diagnostic => show diagnostic.kind == expected)

runDataModelErrors : List ErrorFixture -> Results
runDataModelErrors [] = empty
runDataModelErrors (fixture :: rest) =
  let current = if fixture.expected == "data-model-error"
        then case compile fixture.source of
          Right _ => success
          Left error => failure
            ("official valid normalization case failed: " ++ fixture.source ++ "\n  " ++ show error)
        else case compile fixture.source of
          Left (ValidationFailure diagnostics) => check
            ("wrong semantic error for: " ++ fixture.source
              ++ "\n  expected: " ++ fixture.expected
              ++ "\n  actual: " ++ show (map (.kind) diagnostics))
            (hasNamedKind fixture.expected diagnostics)
          Left (ParseFailure diagnostic) => failure
            ("semantic fixture failed parsing: " ++ fixture.source ++ "\n  " ++ show diagnostic)
          Right _ => failure
            ("official data-model error was accepted: " ++ fixture.source) in
      combine current (runDataModelErrors rest)

record SemanticCase where
  constructor MkSemanticCase
  source : String
  expected : ErrorKind

semanticCases : List SemanticCase
semanticCases =
  [ MkSemanticCase ".input {$x} .match $x one {{one}} * {{other}}" MissingSelectorAnnotation
  , MkSemanticCase ".input {$x :string} .match $x one {{one}}" MissingFallbackVariant
  , MkSemanticCase ".input {$x :string} .match $x * * {{bad}}" VariantKeyMismatch
  , MkSemanticCase ".input {$x} .input {$x} {{bad}}" DuplicateDeclaration
  , MkSemanticCase "{x :f a=1 a=2}" DuplicateOptionName
  , MkSemanticCase ".input {$x :string} .match $x * {{a}} * {{b}}" DuplicateVariant
  , MkSemanticCase ".local $x = {$x} {{bad}}" DuplicateDeclaration
  , MkSemanticCase ".local $x = {$later} .local $later = {42} {{bad}}" DuplicateDeclaration
  , MkSemanticCase ".input {$x :string} .match $x x y {{bad}} * {{fallback}}" VariantKeyMismatch
  , MkSemanticCase ".input {$x :string} .match $x |*| {{literal only}}" MissingFallbackVariant
  ]

runSemanticCases : List SemanticCase -> Results
runSemanticCases [] = empty
runSemanticCases (test :: rest) =
  let current = case compile test.source of
        Left (ValidationFailure diagnostics) => check
          ("missing semantic diagnostic " ++ show test.expected ++ " for " ++ test.source)
          (hasKind test.expected diagnostics)
        _ => failure ("semantic case unexpectedly compiled: " ++ test.source) in
      combine current (runSemanticCases rest)

||| Official data-model fixtures and focused refinement failures colocated with
||| the validator that constructs the dependent IR.
public export
validationTests : Results
validationTests = combine (runDataModelErrors dataModelErrors)
                          (runSemanticCases semanticCases)
