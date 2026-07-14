module MF2.Runtime.Selection

import Data.Vect
import MF2.Decimal
import MF2.IR
import MF2.Runtime.Types
import MF2.Syntax

%default total

||| The four possible outcomes when one selector is compared with one key.
|||
||| Naming the ranks avoids the previous `-1 / 0 / 1 / 2` encoding and makes
||| the lexicographic preference algorithm correspond directly to the spec.
public export
data MatchQuality = NoMatch | CatchallMatch | RuleMatch | ExactMatch

public export
Eq MatchQuality where
  NoMatch == NoMatch = True
  CatchallMatch == CatchallMatch = True
  RuleMatch == RuleMatch = True
  ExactMatch == ExactMatch = True
  _ == _ = False

qualityRank : MatchQuality -> Int
qualityRank NoMatch = -1
qualityRank CatchallMatch = 0
qualityRank RuleMatch = 1
qualityRank ExactMatch = 2

localePrefix : String -> String
localePrefix locale = pack (takeUntilDash (unpack locale))
  where
    takeUntilDash : List Char -> List Char
    takeUntilDash [] = []
    takeUntilDash ('-' :: rest) = []
    takeUntilDash (char :: rest) = char :: takeUntilDash rest

||| Return the teaching backend's plural or ordinal keyword for one decimal.
|||
||| This intentionally covers only the small locale set documented in the
||| conformance matrix. A production handler supplies complete CLDR behavior.
export
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

||| Compare one resolved selector with one variant key.
export
matchQuality : String -> ResolvedValue -> Key -> MatchQuality
matchQuality locale resolved Catchall = CatchallMatch
matchQuality locale resolved (LiteralKey key) = case resolved.selection of
  NoSelection => NoMatch
  StringSelection value => if value == key then ExactMatch else NoMatch
  NumberSelection decimal exact mode => case parseDecimal key of
    Just _ => if exact == key then ExactMatch else NoMatch
    Nothing => if pluralKeyword locale mode decimal == key then RuleMatch else NoMatch

qualities : String -> List ResolvedValue -> List Key -> List MatchQuality
qualities locale [] [] = []
qualities locale (selector :: selectors) (key :: keys) =
  matchQuality locale selector key :: qualities locale selectors keys
qualities locale _ _ = []

allMatched : List MatchQuality -> Bool
allMatched [] = True
allMatched (NoMatch :: rest) = False
allMatched (_ :: rest) = allMatched rest

lexicographicallyBetter : List MatchQuality -> List MatchQuality -> Bool
lexicographicallyBetter [] [] = False
lexicographicallyBetter (left :: lefts) (right :: rights) =
  if qualityRank left > qualityRank right then True
  else if qualityRank left < qualityRank right then False
  else lexicographicallyBetter lefts rights
lexicographicallyBetter _ _ = False

||| Choose the best matching variant, preserving source order for ties.
|||
||| The starting `best` is the statically proved fallback variant, so callers
||| always receive a pattern even when no non-fallback variant matches.
public export
selectBest : String -> List ResolvedValue -> Variant arity
          -> List (Variant arity) -> Variant arity
selectBest locale selectors best [] = best
selectBest locale selectors best (candidate :: rest) =
  let candidateQuality = qualities locale selectors (toList candidate.keys)
      bestQuality = qualities locale selectors (toList best.keys)
      next = if allMatched candidateQuality
                  && lexicographicallyBetter candidateQuality bestQuality
                then candidate else best in
      selectBest locale selectors next rest
