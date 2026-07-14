module TestMain

import System
import OfficialFixtures
import OfficialRuntimeFixtures
import Support.DecimalCases
import Support.FrontendCases
import Support.OfficialRuntimeCases
import Support.Results
import Support.RuntimeCases
import Support.SemanticCases

%default total

printFailures : List String -> IO ()
printFailures [] = pure ()
printFailures (message :: rest) = do
  putStrLn ("FAIL: " ++ message)
  printFailures rest

main : IO ()
main = do
  let results = combine (runValidSyntax validSyntax)
              (combine (runSyntaxErrors syntaxErrors)
              (combine (runDataModelErrors dataModelErrors)
              (combine (decimalRoundTrips integerLiterals)
              (combine decimalEdgeCases
              (combine (runRuntimeCases runtimeCases)
              (combine (runOfficialRuntime officialRuntime)
                       (runSemanticCases semanticCases)))))))
  printFailures results.messages
  putStrLn (show results.passed ++ " passed; " ++ show results.failed ++ " failed")
  if results.failed == 0 then pure () else exitFailure
