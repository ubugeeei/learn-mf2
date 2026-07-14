module MF2.Validate

import Data.Vect
import MF2.Diagnostic
import MF2.IR
import MF2.Syntax

%default total

public export
Validation : Type -> Type
Validation result = Either (List Diagnostic) result
contains : Eq element => element -> List element -> Bool
contains expected [] = False
contains expected (element :: rest) = expected == element || contains expected rest

duplicates : Eq element => List element -> List element
duplicates elements = go [] elements
  where
    go : List element -> List element -> List element
    go seen [] = []
    go seen (element :: rest) =
      if contains element seen
         then element :: go seen rest
         else go (element :: seen) rest
optionErrors : List Option -> List Diagnostic
optionErrors options = map toError (duplicates (map (.name) options))
  where
    findOption : Identifier -> List Option -> Maybe Option
    findOption name [] = Nothing
    findOption name (option :: rest) =
      if option.name == name then Just option else findOption name rest

    optionSpan : Identifier -> Span
    optionSpan name = case findOption name options of
      Nothing => MkSpan 0 0
      Just option => option.span

    toError : Identifier -> Diagnostic
    toError name = MkDiagnostic DuplicateOptionName (optionSpan name)
      ("option `" ++ show name ++ "` occurs more than once")

expressionOptionErrors : Expression -> List Diagnostic
expressionOptionErrors expression = case expression.function of
  Nothing => []
  Just function => optionErrors function.options

partOptionErrors : PatternPart -> List Diagnostic
partOptionErrors (Text _) = []
partOptionErrors (Place expression) = expressionOptionErrors expression
partOptionErrors (Mark markup) = optionErrors markup.options

patternOptionErrors : Pattern -> List Diagnostic
patternOptionErrors pattern = concatMap partOptionErrors pattern

declarationOptionErrors : Declaration -> List Diagnostic
declarationOptionErrors declaration =
  expressionOptionErrors (declarationExpression declaration)

bodyOptionErrors : RawBody -> List Diagnostic
bodyOptionErrors (PatternBody pattern) = patternOptionErrors pattern
bodyOptionErrors (SelectBody _ variants) =
  concatMap (patternOptionErrors . (.value)) variants

operandVariables : Maybe Operand -> List String
operandVariables (Just (Variable name)) = [name]
operandVariables _ = []

optionVariables : List Option -> List String
optionVariables [] = []
optionVariables (option :: rest) = case option.value of
  Variable name => name :: optionVariables rest
  Literal _ => optionVariables rest

functionVariables : Maybe FunctionRef -> List String
functionVariables Nothing = []
functionVariables (Just function) = optionVariables function.options

expressionVariables : Expression -> List String
expressionVariables expression =
  operandVariables expression.operand ++ functionVariables expression.function

declarationErrors : List Declaration -> List Diagnostic
declarationErrors declarations = go [] declarations
  where
    go : List String -> List Declaration -> List Diagnostic
    go seen [] = []
    go seen (declaration :: rest) =
      let name = declaredName declaration
          expression = declarationExpression declaration
          references = case declaration of
            InputDeclaration _ _ _ => functionVariables expression.function
            LocalDeclaration _ _ _ => expressionVariables expression
          repeated = contains name seen || contains name references
          error = MkDiagnostic DuplicateDeclaration expression.span
                    ("variable `$" ++ name ++ "` was already declared or referenced")
          nextSeen = name :: (references ++ seen) in
      (if repeated then [error] else []) ++ go nextSeen rest

AnnotationEnv : Type
AnnotationEnv = List (String, Maybe FunctionRef)

lookupAnnotation : String -> AnnotationEnv -> Maybe FunctionRef
lookupAnnotation name [] = Nothing
lookupAnnotation name ((candidate, annotation) :: rest) =
  if name == candidate then annotation else lookupAnnotation name rest

inheritedAnnotation : Expression -> AnnotationEnv -> Maybe FunctionRef
inheritedAnnotation expression environment = case expression.function of
  Just function => Just function
  Nothing => case expression.operand of
    Just (Variable name) => lookupAnnotation name environment
    _ => Nothing

annotationEnvironment : List Declaration -> AnnotationEnv
annotationEnvironment declarations = go [] declarations
  where
    go : AnnotationEnv -> List Declaration -> AnnotationEnv
    go environment [] = environment
    go environment (declaration :: rest) =
      let name = declaredName declaration
          expression = declarationExpression declaration
          annotation = case declaration of
            InputDeclaration _ _ _ => expression.function
            LocalDeclaration _ _ _ => inheritedAnnotation expression environment
       in go ((name, annotation) :: environment) rest

selectorFor : AnnotationEnv -> String -> Either Diagnostic Selector
selectorFor environment name = case lookupAnnotation name environment of
  Nothing => Left (point MissingSelectorAnnotation 0
                    ("selector `$" ++ name ++ "` does not reference an annotated declaration"))
  Just annotation => Right (MkSelector name annotation)

keyListsEqual : List Key -> List Key -> Bool
keyListsEqual [] [] = True
keyListsEqual (left :: lefts) (right :: rights) =
  left == right && keyListsEqual lefts rights
keyListsEqual _ _ = False

hasDuplicateVariants : List RawVariant -> Bool
hasDuplicateVariants variants = go [] variants
  where
    go : List (List Key) -> List RawVariant -> Bool
    go seen [] = False
    go seen (variant :: rest) =
      any (keyListsEqual variant.keys) seen || go (variant.keys :: seen) rest

allCatchall : List Key -> Bool
allCatchall [] = True
allCatchall (Catchall :: rest) = allCatchall rest
allCatchall (LiteralKey _ :: _) = False

findFallback : List RawVariant -> Maybe RawVariant
findFallback [] = Nothing
findFallback (variant :: rest) =
  if allCatchall variant.keys then Just variant else findFallback rest

variantErrors : Nat -> List RawVariant -> List Diagnostic
variantErrors arity variants =
  let arityErrors = concatMap checkArity variants
      fallbackErrors = case findFallback variants of
        Nothing => [point MissingFallbackVariant 0
                    "a matcher requires a variant containing only catch-all keys"]
        Just _ => []
      duplicateErrors = if hasDuplicateVariants variants
        then [point DuplicateVariant 0 "two variants have the same normalized key list"]
        else []
   in arityErrors ++ fallbackErrors ++ duplicateErrors
  where
    checkArity : RawVariant -> List Diagnostic
    checkArity variant =
      if length variant.keys == arity
         then []
         else [MkDiagnostic VariantKeyMismatch variant.span
               ("expected " ++ show arity ++ " keys, found " ++ show (length variant.keys))]

exactVect : (size : Nat) -> List element -> Maybe (Vect size element)
exactVect Z [] = Just []
exactVect Z (_ :: _) = Nothing
exactVect (S size) [] = Nothing
exactVect (S size) (element :: rest) = map (element ::) (exactVect size rest)

traverseEither : (source -> Either error target) -> List source -> Either error (List target)
traverseEither transform [] = Right []
traverseEither transform (value :: rest) = do
  first <- transform value
  more <- traverseEither transform rest
  Right (first :: more)

compileVariant : (arity : Nat) -> RawVariant -> Maybe (Variant arity)
compileVariant arity variant = do
  keys <- exactVect arity variant.keys
  Just (MkVariant keys variant.value)

compileVariants : (arity : Nat) -> List RawVariant -> Maybe (List (Variant arity))
compileVariants arity [] = Just []
compileVariants arity (variant :: rest) = do
  first <- compileVariant arity variant
  more <- compileVariants arity rest
  Just (first :: more)

proveAllCatchall : (keys : Vect arity Key) -> Maybe (AllCatchall keys)
proveAllCatchall [] = Just EmptyCatchall
proveAllCatchall (Catchall :: rest) = map NextCatchall (proveAllCatchall rest)
proveAllCatchall (LiteralKey _ :: rest) = Nothing

compileFallback : (arity : Nat) -> RawVariant -> Maybe (FallbackVariant arity)
compileFallback arity variant = do
  keys <- exactVect arity variant.keys
  witness <- proveAllCatchall keys
  Just (MkFallbackVariant keys variant.value witness)

compileMatch : List Declaration -> List String -> List RawVariant -> Validation CompiledBody
compileMatch declarations [] variants =
  Left [point VariantKeyMismatch 0 "a matcher cannot have zero selectors"]
compileMatch declarations names@(firstName :: otherNames) rawVariants =
  let environment = annotationEnvironment declarations
      errors = variantErrors (S (length otherNames)) rawVariants in
  case traverseEither (selectorFor environment) names of
    Left selectorError => Left (errors ++ [selectorError])
    Right selectorList =>
      if not (null errors) then Left errors else
      case (exactVect (S (length otherNames)) selectorList,
            compileVariants (S (length otherNames)) rawVariants,
            findFallback rawVariants >>= compileFallback (S (length otherNames))) of
        (Just selectors, Just variants, Just fallback) =>
          Right (Dynamic (length otherNames) (MkMatchPlan selectors variants fallback))
        _ => Left [point VariantKeyMismatch 0
                   "internal arity conversion failed after successful validation"]

||| Validate every stable MF2 data-model constraint and refine raw syntax into
||| dependent IR, accumulating diagnostics for authoring tools.
public export
validate : RawMessage -> Validation CompiledMessage
validate message =
  let optionErrors = concatMap declarationOptionErrors message.declarations
                  ++ bodyOptionErrors message.body
      declarationErrors = declarationErrors message.declarations
      sharedErrors = optionErrors ++ declarationErrors in
  case message.body of
    PatternBody pattern =>
      if null sharedErrors
         then Right (MkCompiledMessage message.declarations (Static pattern))
         else Left sharedErrors
    SelectBody selectors variants =>
      case compileMatch message.declarations selectors variants of
        Left matchErrors => Left (sharedErrors ++ matchErrors)
        Right body => if null sharedErrors
                         then Right (MkCompiledMessage message.declarations body)
                         else Left sharedErrors
