module MF2.TestMain

import System
import MF2.Decimal.Test
import MF2.IR.Test
import MF2.Parser.Test
import MF2.Runtime.Environment.Test
import MF2.Runtime.Fixtures
import MF2.Runtime.Fixtures.Test
import MF2.Runtime.Format.Test
import MF2.Runtime.Handlers.Test
import MF2.Runtime.Selection.Test
import MF2.Testing
import MF2.Validate.Test

%default total

printFailures : List String -> IO ()
printFailures [] = pure ()
printFailures (message :: rest) = do
  putStrLn ("FAIL: " ++ message)
  printFailures rest

main : IO ()
main = do
  let results = combineAll
        [ irTests
        , parserTests
        , validationTests
        , decimalTests
        , environmentTests
        , handlerTests
        , selectionTests
        , formatTests
        , runOfficialRuntime officialRuntime
        ]
  printFailures results.messages
  putStrLn (show results.passed ++ " passed; " ++ show results.failed ++ " failed")
  if results.failed == 0 then pure () else exitFailure
