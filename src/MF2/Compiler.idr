module MF2.Compiler

import MF2.Diagnostic
import MF2.IR
import MF2.Parser
import MF2.Runtime
import MF2.Syntax
import MF2.Validate

%default total

||| Compilation failure preserves the specification boundary between a source
||| that is not well-formed and a well-formed data model that is not valid.
public export
data CompileError : Type where
  ParseFailure : Diagnostic -> CompileError
  ValidationFailure : List Diagnostic -> CompileError

joinLines : List String -> String
joinLines [] = ""
joinLines [line] = line
joinLines (line :: rest) = line ++ "\n" ++ joinLines rest

public export
Show CompileError where
  show (ParseFailure diagnostic) = show diagnostic
  show (ValidationFailure diagnostics) = joinLines (map show diagnostics)

||| Compile untrusted MF2 source into the invariant-rich IR consumed by the
||| formatter. This is the single recommended construction boundary.
public export
compile : String -> Either CompileError CompiledMessage
compile source = case parse source of
  Left diagnostic => Left (ParseFailure diagnostic)
  Right message => case validate message of
    Left diagnostics => Left (ValidationFailure diagnostics)
    Right compiled => Right compiled

||| Convenience API for one-shot applications. Runtime errors are returned
||| alongside the required fallback-containing output.
public export
format : Context -> String -> Either CompileError (String, List Diagnostic)
format context source = map (formatToString context) (compile source)
