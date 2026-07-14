module MF2.Parser.Core

import MF2.Diagnostic
import MF2.Syntax

%default total

||| The parser cursor carries the unconsumed code points and an absolute
||| code-point offset. Parser recursion is fuelled, making termination explicit
||| even for mutually recursive grammar productions.
public export
record Cursor where
  constructor MkCursor
  remaining : List Char
  offset : Nat

public export
ParseResult : Type -> Type
ParseResult result = Either Diagnostic (result, Cursor)

export
syntaxAt : Cursor -> String -> Either Diagnostic result
syntaxAt cursor message = Left (point SyntaxError cursor.offset message)

export
advance : Cursor -> Maybe (Char, Cursor)
advance (MkCursor [] offset) = Nothing
advance (MkCursor (char :: rest) offset) =
  Just (char, MkCursor rest (S offset))

export
peek : Cursor -> Maybe Char
peek (MkCursor [] _) = Nothing
peek (MkCursor (char :: _) _) = Just char

export
startsWithChars : List Char -> List Char -> Bool
startsWithChars [] _ = True
startsWithChars (_ :: _) [] = False
startsWithChars (expected :: more) (actual :: rest) =
  expected == actual && startsWithChars more rest

export
startsWith : String -> Cursor -> Bool
startsWith expected cursor = startsWithChars (unpack expected) cursor.remaining

export
consumeChars : List Char -> Cursor -> Maybe Cursor
consumeChars [] cursor = Just cursor
consumeChars (_ :: _) (MkCursor [] _) = Nothing
consumeChars (expected :: more) (MkCursor (actual :: rest) offset) =
  if expected == actual
     then consumeChars more (MkCursor rest (S offset))
     else Nothing

export
consume : String -> Cursor -> Either Diagnostic Cursor
consume expected cursor = case consumeChars (unpack expected) cursor of
  Nothing => syntaxAt cursor ("expected `" ++ expected ++ "`")
  Just next => Right next

export
isBidi : Char -> Bool
isBidi char =
  let code = ord char in
      code == 0x061C || code == 0x200E || code == 0x200F
   || (code >= 0x2066 && code <= 0x2069)

export
isWhitespace : Char -> Bool
isWhitespace char = char == ' ' || char == '\t' || char == '\r'
                 || char == '\n' || ord char == 0x3000

export
isOptionalSpace : Char -> Bool
isOptionalSpace char = isWhitespace char || isBidi char

export
takeWhileChars : (Char -> Bool) -> List Char -> (Nat, List Char)
takeWhileChars predicate [] = (0, [])
takeWhileChars predicate all@(char :: rest) =
  if predicate char
     then let (count, remaining) = takeWhileChars predicate rest
           in (S count, remaining)
     else (0, all)

export
takeCursorWhile : (Char -> Bool) -> Cursor -> Cursor
takeCursorWhile predicate cursor =
  let (count, remaining) = takeWhileChars predicate cursor.remaining
   in MkCursor remaining (cursor.offset + count)

export
skipOptional : Cursor -> Cursor
skipOptional = takeCursorWhile isOptionalSpace

export
skipRequired : Cursor -> Either Diagnostic Cursor
skipRequired cursor =
  let before = takeCursorWhile isBidi cursor in
  case peek before of
    Just char => if isWhitespace char
                    then Right (skipOptional before)
                    else syntaxAt cursor "required whitespace is missing"
    Nothing => syntaxAt cursor "required whitespace is missing"

export
isForbiddenScalar : Char -> Bool
isForbiddenScalar char =
  let code = ord char
      planeTail = code `mod` 0x10000 in
      code == 0
   || (code >= 0xD800 && code <= 0xDFFF)
   || (code >= 0xFDD0 && code <= 0xFDEF)
   || planeTail == 0xFFFE || planeTail == 0xFFFF

export
isNameStart : Char -> Bool
isNameStart char =
  let code = ord char in
  if isForbiddenScalar char || isWhitespace char || isBidi char then False
  else if code <= 0x7F
    then isAlpha char || char == '+' || char == '_'
    else code /= 0x00A0 && code /= 0x1680 && code /= 0x2028
      && code /= 0x2029 && code /= 0x202F && code /= 0x205F

export
isNameChar : Char -> Bool
isNameChar char = isNameStart char || isDigit char || char == '-' || char == '.'

export
takeNameTail : List Char -> List Char -> Nat -> (List Char, List Char, Nat)
takeNameTail accumulator [] offset = (reverse accumulator, [], offset)
takeNameTail accumulator all@(char :: rest) offset =
  if isNameChar char
     then takeNameTail (char :: accumulator) rest (S offset)
     else (reverse accumulator, all, offset)

export
parseName : Cursor -> ParseResult String
parseName cursor@(MkCursor [] _) = syntaxAt cursor "expected a name"
parseName cursor@(MkCursor (char :: rest) offset) =
  if isNameStart char
     then let (chars, remaining, nextOffset) = takeNameTail [char] rest (S offset)
           in Right (pack chars, MkCursor remaining nextOffset)
     else syntaxAt cursor "expected a valid name-start character"

export
parseIdentifier : Cursor -> ParseResult Identifier
parseIdentifier cursor = do
  (first, afterFirst) <- parseName cursor
  case peek afterFirst of
    Just ':' => do
      afterColon <- consume ":" afterFirst
      (second, afterSecond) <- parseName afterColon
      Right (MkIdentifier (Just first) second, afterSecond)
    _ => Right (MkIdentifier Nothing first, afterFirst)

export
parseVariable : Cursor -> ParseResult String
parseVariable cursor = do
  afterDollar <- consume "$" cursor
  parseName afterDollar

export
parseEscape : Cursor -> ParseResult Char
parseEscape cursor = do
  afterSlash <- consume "\\" cursor
  case advance afterSlash of
    Just (char, next) =>
      if char == '\\' || char == '{' || char == '|' || char == '}'
         then Right (char, next)
         else syntaxAt afterSlash "only reverse solidus, braces, and pipe may be escaped"
    Nothing => syntaxAt afterSlash "an escape must contain a following character"

export
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

export
parseUnquoted : Cursor -> ParseResult String
parseUnquoted cursor@(MkCursor [] _) = syntaxAt cursor "expected an unquoted literal"
parseUnquoted cursor@(MkCursor (char :: rest) offset) =
  if isNameChar char
     then let (chars, remaining, nextOffset) = takeNameTail [char] rest (S offset)
           in Right (pack chars, MkCursor remaining nextOffset)
     else syntaxAt cursor "expected an unquoted literal character"

export
parseLiteral : Nat -> Cursor -> ParseResult String
parseLiteral fuel cursor = case peek cursor of
  Just '|' => do
    next <- consume "|" cursor
    parseQuotedLoop fuel next []
  _ => parseUnquoted cursor

export
parseOperand : Nat -> Cursor -> ParseResult Operand
parseOperand fuel cursor = case peek cursor of
  Just '$' => do
    (name, next) <- parseVariable cursor
    Right (Variable name, next)
  _ => do
    (literal, next) <- parseLiteral fuel cursor
    Right (Literal literal, next)
