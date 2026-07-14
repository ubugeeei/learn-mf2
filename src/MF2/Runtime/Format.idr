module MF2.Runtime.Format

import MF2.Diagnostic
import MF2.IR
import MF2.Runtime.Resolution
import MF2.Runtime.Types
import MF2.Syntax

%default total

||| A structured output part. Markup remains data and is never serialized as
||| executable markup by the default string formatter.
public export
data OutputPart
  = TextOutput String
  | ExpressionOutput String Direction Bool (List Attribute)
  | MarkupOutput MarkupKind Identifier (List (String, Value)) (List Attribute)

||| The formatter returns both usable output and every runtime diagnostic it
||| observed. A valid message therefore always yields a result, even when a
||| variable or handler fails and a spec-defined fallback is inserted.
public export
record FormatResult where
  constructor MkFormatResult
  parts : List OutputPart
  errors : List Diagnostic

formatPart : Context -> ResolvedEnv -> PatternPart
          -> (OutputPart, List Diagnostic)
formatPart context environment (Text value) = (TextOutput value, [])
formatPart context environment (Place expression) =
  let (resolved, errors) = resolveExpression context environment expression
      rendered = if resolved.fallback
                    then "{" ++ resolved.formatted ++ "}"
                    else resolved.formatted in
      (ExpressionOutput rendered resolved.direction resolved.isolate expression.attributes, errors)
formatPart context environment (Mark markup) =
  let (options, errors) = resolveOptions environment markup.options in
      (MarkupOutput markup.kind markup.name options markup.attributes, errors)

formatPattern : Context -> ResolvedEnv -> Pattern -> FormatResult
formatPattern context environment [] = MkFormatResult [] []
formatPattern context environment (part :: rest) =
  let (output, errors) = formatPart context environment part
      later = formatPattern context environment rest in
      MkFormatResult (output :: later.parts) (errors ++ later.errors)

||| Resolve declarations exactly once, select a variant using the arity-safe
||| plan, and produce structured parts suitable for rich-text renderers.
public export
formatToParts : Context -> CompiledMessage -> FormatResult
formatToParts context message =
  let initial = initialEnvironment context.inputs
      (environment, declarationErrors) =
        evaluateDeclarations context initial message.declarations
      (pattern, selectionErrors) = case message.body of
        Static pattern => (pattern, the (List Diagnostic) [])
        Dynamic planTail plan => selectPattern context environment plan
      result = formatPattern context environment pattern in
      MkFormatResult result.parts
        (declarationErrors ++ selectionErrors ++ result.errors)

isolateText : Direction -> Direction -> Bool -> String -> String
isolateText messageDirection LTR requested value =
  if messageDirection == LTR && not requested
     then value else "⁦" ++ value ++ "⁩"
isolateText messageDirection RTL requested value = "⁧" ++ value ++ "⁩"
isolateText messageDirection UnknownDirection requested value = "⁨" ++ value ++ "⁩"

renderPart : Context -> OutputPart -> String
renderPart context (TextOutput value) = value
renderPart context (MarkupOutput _ _ _ _) = ""
renderPart context (ExpressionOutput value direction isolate _) =
  if context.bidiIsolation
     then isolateText context.messageDirection direction isolate value
     else value

||| Render structured parts as a string. Markup becomes empty and the default
||| bidi isolation algorithm wraps expression output when required.
public export
formatToString : Context -> CompiledMessage -> (String, List Diagnostic)
formatToString context message =
  let result = formatToParts context message in
      (concat (map (renderPart context) result.parts), result.errors)
