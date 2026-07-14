module MF2.Parser

import MF2.Diagnostic
import MF2.Syntax

%default total

||| The parser cursor carries the unconsumed code points and an absolute
||| code-point offset. Parser recursion is fuelled, making termination explicit
||| even for mutually recursive grammar productions.
record Cursor where
  constructor MkCursor
  remaining : List Char
  offset : Nat

ParseResult : Type -> Type
ParseResult result = Either Diagnostic (result, Cursor)

syntaxAt : Cursor -> String -> Either Diagnostic result
syntaxAt cursor message = Left (point SyntaxError cursor.offset message)

advance : Cursor -> Maybe (Char, Cursor)
advance (MkCursor [] offset) = Nothing
advance (MkCursor (char :: rest) offset) =
  Just (char, MkCursor rest (S offset))

peek : Cursor -> Maybe Char
peek (MkCursor [] _) = Nothing
peek (MkCursor (char :: _) _) = Just char

startsWithChars : List Char -> List Char -> Bool
startsWithChars [] _ = True
startsWithChars (_ :: _) [] = False
startsWithChars (expected :: more) (actual :: rest) =
  expected == actual && startsWithChars more rest

startsWith : String -> Cursor -> Bool
startsWith expected cursor = startsWithChars (unpack expected) cursor.remaining

consumeChars : List Char -> Cursor -> Maybe Cursor
consumeChars [] cursor = Just cursor
consumeChars (_ :: _) (MkCursor [] _) = Nothing
consumeChars (expected :: more) (MkCursor (actual :: rest) offset) =
  if expected == actual
     then consumeChars more (MkCursor rest (S offset))
     else Nothing

consume : String -> Cursor -> Either Diagnostic Cursor
consume expected cursor = case consumeChars (unpack expected) cursor of
  Nothing => syntaxAt cursor ("expected `" ++ expected ++ "`")
  Just next => Right next

isBidi : Char -> Bool
isBidi char =
  let code = ord char in
      code == 0x061C || code == 0x200E || code == 0x200F
   || (code >= 0x2066 && code <= 0x2069)

isWhitespace : Char -> Bool
isWhitespace char = char == ' ' || char == '\t' || char == '\r'
                 || char == '\n' || ord char == 0x3000

isOptionalSpace : Char -> Bool
isOptionalSpace char = isWhitespace char || isBidi char

takeWhileChars : (Char -> Bool) -> List Char -> (Nat, List Char)
takeWhileChars predicate [] = (0, [])
takeWhileChars predicate all@(char :: rest) =
  if predicate char
     then let (count, remaining) = takeWhileChars predicate rest
           in (S count, remaining)
     else (0, all)

takeCursorWhile : (Char -> Bool) -> Cursor -> Cursor
takeCursorWhile predicate cursor =
  let (count, remaining) = takeWhileChars predicate cursor.remaining
   in MkCursor remaining (cursor.offset + count)

skipOptional : Cursor -> Cursor
skipOptional = takeCursorWhile isOptionalSpace

skipRequired : Cursor -> Either Diagnostic Cursor
skipRequired cursor =
  let before = takeCursorWhile isBidi cursor in
  case peek before of
    Just char => if isWhitespace char
                    then Right (skipOptional before)
                    else syntaxAt cursor "required whitespace is missing"
    Nothing => syntaxAt cursor "required whitespace is missing"

isForbiddenScalar : Char -> Bool
isForbiddenScalar char =
  let code = ord char
      planeTail = code `mod` 0x10000 in
      code == 0
   || (code >= 0xD800 && code <= 0xDFFF)
   || (code >= 0xFDD0 && code <= 0xFDEF)
   || planeTail == 0xFFFE || planeTail == 0xFFFF

isNameStart : Char -> Bool
isNameStart char =
  let code = ord char in
  if isForbiddenScalar char || isWhitespace char || isBidi char then False
  else if code <= 0x7F
    then isAlpha char || char == '+' || char == '_'
    else code /= 0x00A0 && code /= 0x1680 && code /= 0x2028
      && code /= 0x2029 && code /= 0x202F && code /= 0x205F

isNameChar : Char -> Bool
isNameChar char = isNameStart char || isDigit char || char == '-' || char == '.'

takeNameTail : List Char -> List Char -> Nat -> (List Char, List Char, Nat)
takeNameTail accumulator [] offset = (reverse accumulator, [], offset)
takeNameTail accumulator all@(char :: rest) offset =
  if isNameChar char
     then takeNameTail (char :: accumulator) rest (S offset)
     else (reverse accumulator, all, offset)

parseName : Cursor -> ParseResult String
parseName cursor@(MkCursor [] _) = syntaxAt cursor "expected a name"
parseName cursor@(MkCursor (char :: rest) offset) =
  if isNameStart char
     then let (chars, remaining, nextOffset) = takeNameTail [char] rest (S offset)
           in Right (pack chars, MkCursor remaining nextOffset)
     else syntaxAt cursor "expected a valid name-start character"

parseIdentifier : Cursor -> ParseResult Identifier
parseIdentifier cursor = do
  (first, afterFirst) <- parseName cursor
  case peek afterFirst of
    Just ':' => do
      afterColon <- consume ":" afterFirst
      (second, afterSecond) <- parseName afterColon
      Right (MkIdentifier (Just first) second, afterSecond)
    _ => Right (MkIdentifier Nothing first, afterFirst)

parseVariable : Cursor -> ParseResult String
parseVariable cursor = do
  afterDollar <- consume "$" cursor
  parseName afterDollar

parseEscape : Cursor -> ParseResult Char
parseEscape cursor = do
  afterSlash <- consume "\\" cursor
  case advance afterSlash of
    Just (char, next) =>
      if char == '\\' || char == '{' || char == '|' || char == '}'
         then Right (char, next)
         else syntaxAt afterSlash "only reverse solidus, braces, and pipe may be escaped"
    Nothing => syntaxAt afterSlash "an escape must contain a following character"

parseQuotedLoop : Nat -> Cursor -> List Char -> ParseResult String
parseQuotedLoop Z cursor accumulator = syntaxAt cursor "parser fuel exhausted in quoted literal"
parseQuotedLoop (S fuel) cursor accumulator = case peek cursor of
  Nothing => syntaxAt cursor "unterminated quoted literal"
  Just '|' => do
    next <- consume "|" cursor
    Right (pack (reverse accumulator), next)
  Just '\\' => do
    (char, next) <- parseEscape cursor
    parseQuotedLoop fuel next (char :: accumulator)
  Just char =>
    if isForbiddenScalar char
       then syntaxAt cursor "forbidden Unicode scalar value in literal"
       else case advance cursor of
         Nothing => syntaxAt cursor "unterminated quoted literal"
         Just (_, next) => parseQuotedLoop fuel next (char :: accumulator)

parseUnquoted : Cursor -> ParseResult String
parseUnquoted cursor@(MkCursor [] _) = syntaxAt cursor "expected an unquoted literal"
parseUnquoted cursor@(MkCursor (char :: rest) offset) =
  if isNameChar char
     then let (chars, remaining, nextOffset) = takeNameTail [char] rest (S offset)
           in Right (pack chars, MkCursor remaining nextOffset)
     else syntaxAt cursor "expected an unquoted literal character"

parseLiteral : Nat -> Cursor -> ParseResult String
parseLiteral fuel cursor = case peek cursor of
  Just '|' => do
    next <- consume "|" cursor
    parseQuotedLoop fuel next []
  _ => parseUnquoted cursor

parseOperand : Nat -> Cursor -> ParseResult Operand
parseOperand fuel cursor = case peek cursor of
  Just '$' => do
    (name, next) <- parseVariable cursor
    Right (Variable name, next)
  _ => do
    (literal, next) <- parseLiteral fuel cursor
    Right (Literal literal, next)

parseOption : Nat -> Cursor -> ParseResult Option
parseOption fuel cursor = do
  (name, afterName) <- parseIdentifier cursor
  let beforeEquals = skipOptional afterName
  afterEquals <- consume "=" beforeEquals
  let beforeValue = skipOptional afterEquals
  (value, next) <- parseOperand fuel beforeValue
  Right (MkOption name value (MkSpan cursor.offset next.offset), next)

parseOptions : Nat -> Cursor -> ParseResult (List Option)
parseOptions Z cursor = syntaxAt cursor "parser fuel exhausted in options"
parseOptions (S fuel) cursor =
  case skipRequired cursor of
    Left _ => Right ([], cursor)
    Right spaced => case peek spaced of
      Just '@' => Right ([], cursor)
      Just '/' => Right ([], cursor)
      Just '}' => Right ([], cursor)
      _ => if startsWith "{{" spaced
              then Right ([], cursor)
              else case parseOption fuel spaced of
                Left _ => Right ([], cursor)
                Right (option, next) => do
                  (more, end) <- parseOptions fuel next
                  Right (option :: more, end)

parseAttribute : Nat -> Cursor -> ParseResult Attribute
parseAttribute fuel cursor = do
  afterAt <- consume "@" cursor
  (name, afterName) <- parseIdentifier afterAt
  let beforeEquals = skipOptional afterName
  if startsWith "=" beforeEquals
     then do
       afterEquals <- consume "=" beforeEquals
       let beforeValue = skipOptional afterEquals
       (value, next) <- parseLiteral fuel beforeValue
       Right (MkAttribute name (Just value) (MkSpan cursor.offset next.offset), next)
     else Right (MkAttribute name Nothing (MkSpan cursor.offset afterName.offset), afterName)

parseAttributes : Nat -> Cursor -> ParseResult (List Attribute)
parseAttributes Z cursor = syntaxAt cursor "parser fuel exhausted in attributes"
parseAttributes (S fuel) cursor =
  case skipRequired cursor of
    Left _ => Right ([], cursor)
    Right spaced => case peek spaced of
      Just '@' => do
        (attribute, next) <- parseAttribute fuel spaced
        (more, end) <- parseAttributes fuel next
        Right (attribute :: more, end)
      _ => Right ([], cursor)

parseFunction : Nat -> Cursor -> ParseResult FunctionRef
parseFunction fuel cursor = do
  afterColon <- consume ":" cursor
  (name, afterName) <- parseIdentifier afterColon
  (options, next) <- parseOptions fuel afterName
  Right (MkFunctionRef name options (MkSpan cursor.offset next.offset), next)

parseMarkup : Nat -> Nat -> Cursor -> ParseResult Markup
parseMarkup fuel start cursor = do
  (kind, afterMarker) <- case peek cursor of
    Just '#' => do next <- consume "#" cursor; Right (MF2.Syntax.Open, next)
    Just '/' => do next <- consume "/" cursor; Right (MF2.Syntax.Close, next)
    _ => syntaxAt cursor "expected a markup sigil"
  (name, afterName) <- parseIdentifier afterMarker
  (options, afterOptions) <- parseOptions fuel afterName
  (attributes, afterAttributes) <- parseAttributes fuel afterOptions
  let beforeEnd = skipOptional afterAttributes
  case kind of
    MF2.Syntax.Open =>
      if startsWith "/" beforeEnd
         then do
           afterSlash <- consume "/" beforeEnd
           end <- consume "}" (skipOptional afterSlash)
           Right (MkMarkup MF2.Syntax.Standalone name options attributes (MkSpan start end.offset), end)
         else do
           end <- consume "}" beforeEnd
           Right (MkMarkup MF2.Syntax.Open name options attributes (MkSpan start end.offset), end)
    MF2.Syntax.Close => do
      end <- consume "}" beforeEnd
      Right (MkMarkup MF2.Syntax.Close name options attributes (MkSpan start end.offset), end)
    MF2.Syntax.Standalone => syntaxAt cursor "internal parser state error"

parseExpression : Nat -> Nat -> Cursor -> ParseResult Expression
parseExpression Z start cursor = syntaxAt cursor "parser fuel exhausted in expression"
parseExpression (S fuel) start cursor = do
  let beginning = skipOptional cursor
  (operand, function, afterFunction) <- case peek beginning of
    Just ':' => do
      (function, next) <- parseFunction fuel beginning
      Right (Nothing, Just function, next)
    _ => do
      (operand, afterOperand) <- parseOperand fuel beginning
      case skipRequired afterOperand of
        Right spaced => case peek spaced of
          Just ':' => do
            (function, next) <- parseFunction fuel spaced
            Right (Just operand, Just function, next)
          _ => Right (Just operand, Nothing, afterOperand)
        Left _ => Right (Just operand, Nothing, afterOperand)
  (attributes, afterAttributes) <- parseAttributes fuel afterFunction
  let beforeEnd = skipOptional afterAttributes
  end <- consume "}" beforeEnd
  Right (MkExpression operand function attributes (MkSpan start end.offset), end)

parsePlaceholder : Nat -> Cursor -> ParseResult PatternPart
parsePlaceholder Z cursor = syntaxAt cursor "parser fuel exhausted in placeholder"
parsePlaceholder (S fuel) cursor = do
  let start = cursor.offset
  afterOpen <- consume "{" cursor
  let beginning = skipOptional afterOpen
  case peek beginning of
    Just '#' => do
      (markup, next) <- parseMarkup fuel start beginning
      Right (Mark markup, next)
    Just '/' => do
      (markup, next) <- parseMarkup fuel start beginning
      Right (Mark markup, next)
    _ => do
      (expression, next) <- parseExpression fuel start afterOpen
      Right (Place expression, next)

appendText : String -> List PatternPart -> List PatternPart
appendText "" parts = parts
appendText value (Text previous :: rest) = Text (previous ++ value) :: rest
appendText value parts = Text value :: parts

takeText : List Char -> List Char -> Nat -> (String, Cursor)
takeText accumulator [] offset = (pack (reverse accumulator), MkCursor [] offset)
takeText accumulator all@(char :: rest) offset =
  if char == '{' || char == '}' || char == '\\' || isForbiddenScalar char
     then (pack (reverse accumulator), MkCursor all offset)
     else takeText (char :: accumulator) rest (S offset)

parsePatternLoop : Nat -> Bool -> Cursor -> List PatternPart -> ParseResult (List PatternPart)
parsePatternLoop Z quoted cursor accumulator = syntaxAt cursor "parser fuel exhausted in pattern"
parsePatternLoop (S fuel) quoted cursor accumulator =
  if quoted && startsWith "}}" cursor
     then Right (reverse accumulator, cursor)
     else case peek cursor of
       Nothing => if quoted
                     then syntaxAt cursor "unterminated quoted pattern"
                     else Right (reverse accumulator, cursor)
       Just '{' => do
         (part, next) <- parsePlaceholder fuel cursor
         parsePatternLoop fuel quoted next (part :: accumulator)
       Just '}' => syntaxAt cursor "unescaped closing brace in pattern"
       Just '\\' => do
         (char, next) <- parseEscape cursor
         parsePatternLoop fuel quoted next (appendText (pack [char]) accumulator)
       Just char =>
         if isForbiddenScalar char
            then syntaxAt cursor "forbidden Unicode scalar value in pattern"
            else let (text, next) = takeText [] cursor.remaining cursor.offset in
                 if text == ""
                    then syntaxAt cursor "invalid pattern character"
                    else parsePatternLoop fuel quoted next (appendText text accumulator)

parsePattern : Nat -> Bool -> Cursor -> ParseResult (List PatternPart)
parsePattern fuel quoted cursor = parsePatternLoop fuel quoted cursor []

parseQuotedPattern : Nat -> Cursor -> ParseResult Pattern
parseQuotedPattern fuel cursor = do
  afterOpen <- consume "{{" cursor
  (pattern, beforeEnd) <- parsePattern fuel True afterOpen
  end <- consume "}}" beforeEnd
  Right (pattern, end)

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

parseKey : Nat -> Cursor -> ParseResult Key
parseKey fuel cursor = case peek cursor of
  Just '*' => do
    next <- consume "*" cursor
    Right (Catchall, next)
  _ => do
    (value, next) <- parseLiteral fuel cursor
    Right (LiteralKey value, next)

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
