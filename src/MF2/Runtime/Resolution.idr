module MF2.Runtime.Resolution

import Data.Vect
import MF2.Diagnostic
import MF2.IR
import MF2.Runtime.Environment
import MF2.Runtime.Handlers
import MF2.Runtime.Selection
import MF2.Runtime.Types
import MF2.Syntax

%default total

resolveOptionalOperand : ResolvedEnv -> Maybe Operand
                      -> (Maybe ResolvedValue, List Diagnostic)
resolveOptionalOperand environment Nothing = (Nothing, [])
resolveOptionalOperand environment (Just operand) =
  let (resolved, errors) = resolveOperand environment operand in
      (Just resolved, errors)

unannotatedResult : Expression -> Maybe ResolvedValue -> List Diagnostic
                 -> (ResolvedValue, List Diagnostic)
unannotatedResult expression (Just resolved) errors = (resolved, errors)
unannotatedResult expression Nothing errors =
  (fallbackResolved expression,
   runtimeDiagnostic BadOperand expression.span
     "an expression must contain an operand or function" :: errors)

invokeFunction : Context -> ResolvedEnv -> Expression -> FunctionRef
              -> Maybe ResolvedValue -> List Diagnostic
              -> (ResolvedValue, List Diagnostic)
invokeFunction context environment expression function operand earlierErrors =
  let (options, optionErrors) = resolveOptions environment function.options
      functionContext = MkFunctionContext context.locale context.messageDirection
      result = case findCustom function.name context.registry of
        Just handler => Just (handler.run functionContext operand options)
        Nothing => runDefault functionContext function (map (.unwrapped) operand) options
      errors = earlierErrors ++ optionErrors in
  case result of
    Nothing => (fallbackResolved expression,
      errors ++ [runtimeDiagnostic UnknownFunction function.span
        ("no handler is registered for `:" ++ show function.name ++ "`")])
    Just (Left error) => (fallbackResolved expression, errors ++ [error])
    Just (Right value) => (value, errors)

||| Resolve one expression against the current immutable environment.
|||
||| Operand failure short-circuits function invocation but still returns a
||| fallback. Option and handler diagnostics accumulate without preventing the
||| containing valid message from producing output.
public export
resolveExpression : Context -> ResolvedEnv -> Expression
                 -> (ResolvedValue, List Diagnostic)
resolveExpression context environment expression =
  let (operand, operandErrors) = resolveOptionalOperand environment expression.operand in
  case expression.function of
    Nothing => unannotatedResult expression operand operandErrors
    Just function => case operand of
      Just resolved => if resolved.fallback
        then (fallbackResolved expression, operandErrors)
        else invokeFunction context environment expression function operand operandErrors
      Nothing => invokeFunction context environment expression function Nothing operandErrors

||| Evaluate declarations exactly once in source order.
|||
||| The returned environment is effectively the runtime memo table required by
||| MF2's at-most-once declaration semantics.
public export
evaluateDeclarations : Context -> ResolvedEnv -> List Declaration
                    -> (ResolvedEnv, List Diagnostic)
evaluateDeclarations context environment [] = (environment, [])
evaluateDeclarations context environment (declaration :: rest) =
  let name = declaredName declaration
      expression = declarationExpression declaration
      (resolved, errors) = resolveExpression context environment expression
      nextEnvironment = putResolved name resolved environment
      (finalEnvironment, laterErrors) =
        evaluateDeclarations context nextEnvironment rest in
      (finalEnvironment, errors ++ laterErrors)

fallbackVariant : FallbackVariant arity -> Variant arity
fallbackVariant fallback = MkVariant fallback.keys fallback.value

resolveSelectors : ResolvedEnv -> List Selector
                -> (List ResolvedValue, List Diagnostic)
resolveSelectors environment [] = ([], [])
resolveSelectors environment (selector :: rest) =
  let (more, laterErrors) = resolveSelectors environment rest
      fallback = rawResolved (FallbackValue ("$" ++ selector.variable)) in
  case lookupResolved selector.variable environment of
    Just value => case value.selection of
      NoSelection => (fallback :: more,
        point BadSelector 0
          ("`$" ++ selector.variable ++ "` does not support selection") :: laterErrors)
      _ => (value :: more, laterErrors)
    Nothing => (fallback :: more,
      point BadSelector 0
        ("`$" ++ selector.variable ++ "` is unresolved") :: laterErrors)

||| Resolve the arity-safe selector vector and choose one pattern.
public export
selectPattern : Context -> ResolvedEnv -> MatchPlan planTail
             -> (Pattern, List Diagnostic)
selectPattern context environment plan =
  let (selectors, errors) = resolveSelectors environment (toList plan.selectors)
      fallback = fallbackVariant plan.fallback
      best = selectBest context.locale selectors fallback plan.variants in
      (best.value, errors)
