module MF2.Parser.Message

import MF2.Diagnostic
import MF2.Parser.Core
import MF2.Parser.Expression
import MF2.Syntax

%default total

export
parseInputDeclaration : Nat -> Cursor -> ParseResult Declaration
parseInputDeclaration fuel cursor = do
  afterKeyword <- consume ".input" cursor
  let beforeExpression = skipOptional afterKeyword
  (part, next) <- parsePlaceholder fuel beforeExpression
  case part of
    Place expression => case expression.operand of
      Just (Variable name) =>
        Right (InputDeclaration name expression (MkSpan cursor.offset next.offset), next)
      _ => syntaxAt beforeExpression "an input declaration requires a variable expression"
    _ => syntaxAt beforeExpression "an input declaration requires an expression"

export
parseLocalDeclaration : Nat -> Cursor -> ParseResult Declaration
parseLocalDeclaration fuel cursor = do
  afterKeyword <- consume ".local" cursor
  beforeVariable <- skipRequired afterKeyword
  (name, afterVariable) <- parseVariable beforeVariable
  afterEquals <- consume "=" (skipOptional afterVariable)
  let beforeExpression = skipOptional afterEquals
  (part, next) <- parsePlaceholder fuel beforeExpression
  case part of
    Place expression =>
      Right (LocalDeclaration name expression (MkSpan cursor.offset next.offset), next)
    _ => syntaxAt beforeExpression "a local declaration requires an expression"

export
parseDeclarations : Nat -> Cursor -> ParseResult (List Declaration)
parseDeclarations Z cursor = syntaxAt cursor "parser fuel exhausted in declarations"
parseDeclarations (S fuel) cursor =
  let beginning = skipOptional cursor in
  if startsWith ".input" beginning
     then do
       (declaration, next) <- parseInputDeclaration fuel beginning
       (more, end) <- parseDeclarations fuel next
       Right (declaration :: more, end)
  else if startsWith ".local" beginning
     then do
       (declaration, next) <- parseLocalDeclaration fuel beginning
       (more, end) <- parseDeclarations fuel next
       Right (declaration :: more, end)
  else Right ([], beginning)

export
parseSelectors : Nat -> Cursor -> ParseResult (List String)
parseSelectors Z cursor = syntaxAt cursor "parser fuel exhausted in selectors"
parseSelectors (S fuel) cursor = case skipRequired cursor of
  Left _ => Right ([], cursor)
  Right spaced => case peek spaced of
    Just '$' => do
      (name, next) <- parseVariable spaced
      (more, end) <- parseSelectors fuel next
      Right (name :: more, end)
    _ => Right ([], cursor)

export
parseKey : Nat -> Cursor -> ParseResult Key
parseKey fuel cursor = case peek cursor of
  Just '*' => do
    next <- consume "*" cursor
    Right (Catchall, next)
  _ => do
    (value, next) <- parseLiteral fuel cursor
    Right (LiteralKey value, next)

export
parseVariantKeys : Nat -> Cursor -> ParseResult (List Key)
parseVariantKeys Z cursor = syntaxAt cursor "parser fuel exhausted in variant keys"
parseVariantKeys (S fuel) cursor = do
  (first, afterFirst) <- parseKey fuel cursor
  gather fuel afterFirst [first]
  where
    gather : Nat -> Cursor -> List Key -> ParseResult (List Key)
    gather Z cursor accumulator = syntaxAt cursor "parser fuel exhausted in variant keys"
    gather (S remainingFuel) cursor accumulator =
      let beforePattern = skipOptional cursor in
      if startsWith "{{" beforePattern
         then Right (reverse accumulator, beforePattern)
         else case skipRequired cursor of
           Left _ => syntaxAt cursor "expected a quoted pattern after variant keys"
           Right spaced => do
             (key, next) <- parseKey remainingFuel spaced
             gather remainingFuel next (key :: accumulator)

export
parseVariants : Nat -> Cursor -> ParseResult (List RawVariant)
parseVariants Z cursor = syntaxAt cursor "parser fuel exhausted in variants"
parseVariants (S fuel) cursor =
  let beginning = skipOptional cursor in
  case peek beginning of
    Nothing => Right ([], beginning)
    Just _ => do
      let start = beginning.offset
      (keys, beforePattern) <- parseVariantKeys fuel beginning
      (pattern, next) <- parseQuotedPattern fuel beforePattern
      let variant = MkRawVariant keys pattern (MkSpan start next.offset)
      (more, end) <- parseVariants fuel next
      Right (variant :: more, end)

export
parseComplex : Nat -> Cursor -> ParseResult RawMessage
parseComplex fuel cursor = do
  (declarations, afterDeclarations) <- parseDeclarations fuel cursor
  let bodyStart = skipOptional afterDeclarations
  if startsWith "{{" bodyStart
     then do
       (pattern, next) <- parseQuotedPattern fuel bodyStart
       let end = skipOptional next
       case peek end of
         Nothing => Right (MkRawMessage declarations (PatternBody pattern), end)
         Just _ => syntaxAt end "unexpected input after quoted pattern"
     else if startsWith ".match" bodyStart
       then do
         afterMatch <- consume ".match" bodyStart
         (selectors, afterSelectors) <- parseSelectors fuel afterMatch
         case selectors of
           [] => syntaxAt afterMatch "a matcher requires at least one selector"
           _ => do
             beforeVariants <- skipRequired afterSelectors
             (variants, end) <- parseVariants fuel beforeVariants
             case variants of
               [] => syntaxAt beforeVariants "a matcher requires at least one variant"
               _ => case peek (skipOptional end) of
                 Nothing => Right (MkRawMessage declarations (SelectBody selectors variants), end)
                 Just _ => syntaxAt end "unexpected input after matcher"
       else syntaxAt bodyStart "a complex message requires a quoted pattern or matcher"

||| Parse a MessageFormat source into a well-formed raw data model. This phase
||| reports syntax errors only; use `compile` to enforce semantic validity.
public export
parse : String -> Either Diagnostic RawMessage
parse source =
  let chars = unpack source
      cursor = MkCursor chars 0
      fuel = S (length chars * 3) in
  if startsWith "." (skipOptional cursor) || startsWith "{{" (skipOptional cursor)
     then map fst (parseComplex fuel cursor)
     else do
       (pattern, end) <- parsePattern fuel False cursor
       case peek end of
         Nothing => Right (MkRawMessage [] (PatternBody pattern))
         Just _ => syntaxAt end "unexpected input after simple message"
