module MF2.Parser.Test

import MF2.Diagnostic
import MF2.Parser
import MF2.Parser.Fixtures
import MF2.Syntax
import MF2.Testing

%default total

runValidSyntax : List Fixture -> Results
runValidSyntax [] = empty
runValidSyntax (fixture :: rest) =
  let current = case parse fixture.source of
        Right _ => success
        Left diagnostic => failure
          ("official valid syntax failed: " ++ fixture.description ++ "\n  "
            ++ show diagnostic ++ "\n  source: " ++ fixture.source) in
      combine current (runValidSyntax rest)

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

parses : String -> Bool
parses source = case parse source of Right _ => True; Left _ => False

rejects : String -> Bool
rejects = not . parses

||| Official Version 48.2 syntax fixtures plus small boundary cases kept next
||| to the parser implementation for fast diagnosis.
public export
parserTests : Results
parserTests = combineAll
  [ runValidSyntax validSyntax
  , runSyntaxErrors syntaxErrors
  , checkAll
      [ ("empty simple message", parses "")
      , ("Unicode variable name", parses "{$éclair}")
      , ("quoted literal preserves spaces", parses "{|a b|}")
      , ("escaped braces", parses "\\{value\\}")
      , ("standalone markup", parses "{#icon name=warning /}")
      , ("unterminated placeholder", rejects "{$name")
      , ("unknown escape", rejects "\\n")
      , ("empty placeholder", rejects "{}")
      , ("matcher without selector", rejects ".match * {{bad}}")
      , ("matcher without variant", rejects ".input {$x :string} .match $x")
      ]
  ]
