module MF2.Parser.Expression

import MF2.Diagnostic
import MF2.Parser.Core
import MF2.Syntax

%default total

export
parseOption : Nat -> Cursor -> ParseResult Option
parseOption fuel cursor = do
  (name, afterName) <- parseIdentifier cursor
  let beforeEquals = skipOptional afterName
  afterEquals <- consume "=" beforeEquals
  let beforeValue = skipOptional afterEquals
  (value, next) <- parseOperand fuel beforeValue
  Right (MkOption name value (MkSpan cursor.offset next.offset), next)

export
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

export
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

export
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

export
parseFunction : Nat -> Cursor -> ParseResult FunctionRef
parseFunction fuel cursor = do
  afterColon <- consume ":" cursor
  (name, afterName) <- parseIdentifier afterColon
  (options, next) <- parseOptions fuel afterName
  Right (MkFunctionRef name options (MkSpan cursor.offset next.offset), next)

export
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

export
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

export
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

export
appendText : String -> List PatternPart -> List PatternPart
appendText "" parts = parts
appendText value (Text previous :: rest) = Text (previous ++ value) :: rest
appendText value parts = Text value :: parts

export
takeText : List Char -> List Char -> Nat -> (String, Cursor)
takeText accumulator [] offset = (pack (reverse accumulator), MkCursor [] offset)
takeText accumulator all@(char :: rest) offset =
  if char == '{' || char == '}' || char == '\\' || isForbiddenScalar char
     then (pack (reverse accumulator), MkCursor all offset)
     else takeText (char :: accumulator) rest (S offset)

export
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

export
parsePattern : Nat -> Bool -> Cursor -> ParseResult (List PatternPart)
parsePattern fuel quoted cursor = parsePatternLoop fuel quoted cursor []

export
parseQuotedPattern : Nat -> Cursor -> ParseResult Pattern
parseQuotedPattern fuel cursor = do
  afterOpen <- consume "{{" cursor
  (pattern, beforeEnd) <- parsePattern fuel True afterOpen
  end <- consume "}}" beforeEnd
  Right (pattern, end)
