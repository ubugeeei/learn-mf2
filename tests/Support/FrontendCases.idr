module Support.FrontendCases

import MF2.Compiler
import MF2.Diagnostic
import MF2.IR
import MF2.Parser
import MF2.Syntax
import OfficialFixtures
import Support.Results

%default total

public export
runValidSyntax : List Fixture -> Results
runValidSyntax [] = empty
runValidSyntax (fixture :: rest) =
  let current = case parse fixture.source of
        Right _ => success
        Left diagnostic => failure
          ("official valid syntax failed: " ++ fixture.description ++ "\n  " ++ show diagnostic
            ++ "\n  source: " ++ fixture.source) in
      combine current (runValidSyntax rest)

public export
runSyntaxErrors : List Fixture -> Results
runSyntaxErrors [] = empty
runSyntaxErrors (fixture :: rest) =
  let current = case parse fixture.source of
        Left diagnostic => check
          ("wrong parser diagnostic for: " ++ fixture.source)
          (diagnostic.kind == SyntaxError)
        Right _ => failure
          ("official syntax error was accepted: " ++ fixture.description
            ++ "\n  source: " ++ fixture.source) in
      combine current (runSyntaxErrors rest)

hasKind : String -> List Diagnostic -> Bool
hasKind expected [] = False
hasKind expected (diagnostic :: rest) =
  show diagnostic.kind == expected || hasKind expected rest

public export
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
            (hasKind fixture.expected diagnostics)
          Left (ParseFailure diagnostic) => failure
            ("semantic fixture failed parsing: " ++ fixture.source ++ "\n  " ++ show diagnostic)
          Right _ => failure
            ("official data-model error was accepted: " ++ fixture.source) in
      combine current (runDataModelErrors rest)
