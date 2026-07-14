module Main

import System
import MF2.Compiler
import MF2.Decimal
import MF2.Diagnostic
import MF2.IR
import MF2.Runtime

%default total

usage : String
usage = "Usage:\n"
     ++ "  mf2 check MESSAGE\n"
     ++ "  mf2 format MESSAGE [name=value ...]\n\n"
     ++ "Values matching number-literal are passed as exact decimals; all others as strings."

splitAssignment : List Char -> Maybe (String, String)
splitAssignment chars = go [] chars
  where
    go : List Char -> List Char -> Maybe (String, String)
    go before [] = Nothing
    go before ('=' :: rest) = Just (pack (reverse before), pack rest)
    go before (char :: rest) = go (char :: before) rest

parseInput : String -> Maybe (String, Value)
parseInput source = do
  (name, value) <- splitAssignment (unpack source)
  if name == "" then Nothing else
    case parseDecimal value of
      Just decimal => Just (name, NumberValue decimal)
      Nothing => Just (name, StringValue value)

parseInputs : List String -> Either String (List (String, Value))
parseInputs [] = Right []
parseInputs (source :: rest) = case parseInput source of
  Nothing => Left ("invalid input assignment: " ++ source)
  Just input => map (input ::) (parseInputs rest)

showDiagnostics : List Diagnostic -> IO ()
showDiagnostics [] = pure ()
showDiagnostics (diagnostic :: rest) = do
  putStrLn ("warning: " ++ show diagnostic)
  showDiagnostics rest

runCheck : String -> IO ()
runCheck source = case compile source of
  Left error => do
    putStrLn (show error)
    exitFailure
  Right _ => putStrLn "valid"

runFormat : String -> List String -> IO ()
runFormat source assignments = case parseInputs assignments of
  Left error => do
    putStrLn error
    exitFailure
  Right inputs => case format ({ bidiIsolation := False } (defaultContext inputs)) source of
    Left error => do
      putStrLn (show error)
      exitFailure
    Right (output, diagnostics) => do
      putStrLn output
      showDiagnostics diagnostics

main : IO ()
main = do
  arguments <- getArgs
  case arguments of
    [program, "check", source] => runCheck source
    program :: "format" :: source :: assignments => runFormat source assignments
    _ => do
      putStrLn usage
      exitFailure
