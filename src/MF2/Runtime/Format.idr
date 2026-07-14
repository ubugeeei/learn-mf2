module MF2.Runtime.Format

import MF2.Diagnostic
import MF2.IR
import MF2.Runtime.Environment
import MF2.Runtime.Resolution
import MF2.Runtime.Types
import MF2.Syntax

%default total

renderResolved : ResolvedValue -> String
renderResolved resolved =
  if resolved.fallback
     then "{" ++ resolved.formatted ++ "}"
     else resolved.formatted

formatPart : Context -> ResolvedEnv -> PatternPart
          -> (OutputPart, List Diagnostic)
formatPart context environment (Text value) = (TextOutput value, [])
formatPart context environment (Place expression) =
  let (resolved, errors) = resolveExpression context environment expression in
      (ExpressionOutput (renderResolved resolved) resolved.direction
        resolved.isolate expression.attributes, errors)
formatPart context environment (Mark markup) =
  let (options, errors) = resolveOptions environment markup.options in
      (MarkupOutput markup.kind markup.name options markup.attributes, errors)

formatPattern : Context -> ResolvedEnv -> Pattern -> FormatResult
formatPattern context environment [] = MkFormatResult [] []
formatPattern context environment (part :: rest) =
  let (output, errors) = formatPart context environment part
      later = formatPattern context environment rest in
      MkFormatResult (output :: later.parts) (errors ++ later.errors)

choosePattern : Context -> ResolvedEnv -> CompiledBody
             -> (Pattern, List Diagnostic)
choosePattern context environment (Static pattern) = (pattern, [])
choosePattern context environment (Dynamic planTail plan) =
  selectPattern context environment plan

||| Evaluate declarations, select at most one variant, and format its pattern.
|||
||| The result remains structured so rich-text clients can interpret markup
||| through an allowlist rather than through string concatenation.
public export
formatToParts : Context -> CompiledMessage -> FormatResult
formatToParts context message =
  let initial = initialEnvironment context.inputs
      (environment, declarationErrors) =
        evaluateDeclarations context initial message.declarations
      (pattern, selectionErrors) = choosePattern context environment message.body
      result = formatPattern context environment pattern in
      MkFormatResult result.parts
        (declarationErrors ++ selectionErrors ++ result.errors)

||| Apply the Unicode isolate controls required by the default bidi strategy.
public export
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

||| Render structured parts to a string.
|||
||| Markup becomes empty and expression text receives bidi isolation when the
||| context enables the default strategy.
public export
formatToString : Context -> CompiledMessage -> (String, List Diagnostic)
formatToString context message =
  let result = formatToParts context message in
      (concat (map (renderPart context) result.parts), result.errors)
