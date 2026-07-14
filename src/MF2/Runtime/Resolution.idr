module MF2.Runtime.Resolution

import Data.Vect
import MF2.Decimal
import MF2.Diagnostic
import MF2.IR
import MF2.Runtime.Handlers
import MF2.Runtime.Types
import MF2.Syntax

%default total

public export
resolveExpression : Context -> ResolvedEnv -> Expression
                 -> (ResolvedValue, List Diagnostic)
resolveExpression context environment expression =
  let (operand, operandErrors) = case expression.operand of
        Nothing => (Nothing, the (List Diagnostic) [])
        Just source => let (resolved, errors) = resolveOperand environment source
                        in (Just resolved, errors) in
  case expression.function of
    Nothing => case operand of
      Just resolved => (resolved, operandErrors)
      Nothing => (fallbackResolved expression,
                  runtimeDiagnostic BadOperand expression.span
                    "an expression must contain an operand or function" :: operandErrors)
    Just function => case operand of
      Just resolved => if resolved.fallback
        then (fallbackResolved expression, operandErrors)
        else invoke function (Just resolved) operandErrors
      Nothing => invoke function Nothing operandErrors
  where
    invoke : FunctionRef -> Maybe ResolvedValue -> List Diagnostic
          -> (ResolvedValue, List Diagnostic)
    invoke function operand earlierErrors =
      let (options, optionErrors) = resolveOptions environment function.options
          functionContext = MkFunctionContext context.locale context.messageDirection
          result = case findCustom function.name context.registry of
            Just handler => Just (handler.run functionContext operand options)
            Nothing => runDefault functionContext function (map (.unwrapped) operand) options in
      case result of
        Nothing => (fallbackResolved expression,
          earlierErrors ++ optionErrors ++
          [runtimeDiagnostic UnknownFunction function.span
            ("no handler is registered for `:" ++ show function.name ++ "`")])
        Just (Left error) => (fallbackResolved expression,
                              earlierErrors ++ optionErrors ++ [error])
        Just (Right value) => (value, earlierErrors ++ optionErrors)

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

localePrefix : String -> String
localePrefix locale = pack (takeUntilDash (unpack locale))
  where
    takeUntilDash : List Char -> List Char
    takeUntilDash [] = []
    takeUntilDash ('-' :: rest) = []
    takeUntilDash (char :: rest) = char :: takeUntilDash rest

pluralKeyword : String -> String -> Decimal -> String
pluralKeyword locale "exact" decimal = ""
pluralKeyword locale "ordinal" decimal = case wholeValue decimal of
  Nothing => "other"
  Just value => if localePrefix locale == "en"
    then let mod10 = abs value `mod` 10
             mod100 = abs value `mod` 100 in
         if mod10 == 1 && mod100 /= 11 then "one"
         else if mod10 == 2 && mod100 /= 12 then "two"
         else if mod10 == 3 && mod100 /= 13 then "few"
         else "other"
    else "other"
pluralKeyword locale mode decimal = case localePrefix locale of
  "ja" => "other"
  "zh" => "other"
  "ko" => "other"
  "fr" => case wholeValue decimal of
    Just 0 => "one"
    Just 1 => "one"
    _ => "other"
  "en" => case wholeValue decimal of
    Just 1 => "one"
    _ => "other"
  _ => case wholeValue decimal of
    Just 1 => "one"
    _ => "other"

selectionScore : String -> ResolvedValue -> Key -> Int
selectionScore locale resolved Catchall = 0
selectionScore locale resolved (LiteralKey key) = case resolved.selection of
  NoSelection => -1
  StringSelection value => if value == key then 2 else -1
  NumberSelection decimal exact mode => case parseDecimal key of
    Just keyValue => if exact == key then 2 else -1
    Nothing => if pluralKeyword locale mode decimal == key then 1 else -1

scores : String -> List ResolvedValue -> List Key -> List Int
scores locale [] [] = []
scores locale (selector :: selectors) (key :: keys) =
  selectionScore locale selector key :: scores locale selectors keys
scores locale _ _ = []

allMatched : List Int -> Bool
allMatched [] = True
allMatched (score :: rest) = score >= 0 && allMatched rest

betterScores : List Int -> List Int -> Bool
betterScores [] [] = False
betterScores (left :: lefts) (right :: rights) =
  if left > right then True
  else if left < right then False
  else betterScores lefts rights
betterScores _ _ = False

public export
selectBest : String -> List ResolvedValue -> Variant arity
          -> List (Variant arity) -> Variant arity
selectBest locale selectors best [] = best
selectBest locale selectors best (candidate :: rest) =
  let candidateScores = scores locale selectors (toList candidate.keys)
      bestScores = scores locale selectors (toList best.keys)
      next = if allMatched candidateScores && betterScores candidateScores bestScores
                then candidate else best in
      selectBest locale selectors next rest

fallbackVariant : FallbackVariant arity -> Variant arity
fallbackVariant fallback = MkVariant fallback.keys fallback.value

resolveSelectors : ResolvedEnv -> List Selector
                -> (List ResolvedValue, List Diagnostic)
resolveSelectors environment [] = ([], [])
resolveSelectors environment (selector :: rest) =
  let (more, laterErrors) = resolveSelectors environment rest in
  case lookupResolved selector.variable environment of
    Just value => case value.selection of
      NoSelection => (rawResolved (FallbackValue ("$" ++ selector.variable)) :: more,
        point BadSelector 0 ("`$" ++ selector.variable ++ "` does not support selection") :: laterErrors)
      _ => (value :: more, laterErrors)
    Nothing => (rawResolved (FallbackValue ("$" ++ selector.variable)) :: more,
      point BadSelector 0 ("`$" ++ selector.variable ++ "` is unresolved") :: laterErrors)

public export
selectPattern : Context -> ResolvedEnv -> MatchPlan planTail
             -> (Pattern, List Diagnostic)
selectPattern context environment plan =
  let (selectors, errors) = resolveSelectors environment (toList plan.selectors)
      best = selectBest context.locale selectors (fallbackVariant plan.fallback) plan.variants in
      (best.value, errors)
