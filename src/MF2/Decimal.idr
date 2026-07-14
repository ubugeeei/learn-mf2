module MF2.Decimal

%default total

||| An arbitrary-precision base-10 value. Unlike `Double`, this representation
||| can round-trip every MF2 number literal without loss and makes decimal scale
||| available to plural selection.
public export
record Decimal where
  constructor MkDecimal
  coefficient : Integer
  scale : Nat

pow10 : Nat -> Integer
pow10 Z = 1
pow10 (S exponent) = 10 * pow10 exponent

||| Remove insignificant trailing zeroes. Normalization gives numeric equality
||| a small canonical form while retaining arbitrary precision.
public export
normalize : Decimal -> Decimal
normalize (MkDecimal coefficient scale) = normalizeParts coefficient scale
  where
    normalizeParts : Integer -> (digits : Nat) -> Decimal
    normalizeParts coefficient Z = MkDecimal coefficient Z
    normalizeParts coefficient (S digits) =
      if coefficient `mod` 10 == 0
         then normalizeParts (coefficient `div` 10) digits
         else MkDecimal coefficient (S digits)

public export
Eq Decimal where
  left == right =
    let left = normalize left
        right = normalize right in
        left.coefficient == right.coefficient && left.scale == right.scale

digitsOnly : List Char -> Bool
digitsOnly [] = False
digitsOnly chars = all isDigit chars

validIntegerDigits : List Char -> Bool
validIntegerDigits ['0'] = True
validIntegerDigits (first :: rest) = first >= '1' && first <= '9' && all isDigit rest
validIntegerDigits [] = False

splitOnce : Char -> List Char -> Maybe (List Char, List Char)
splitOnce needle chars = go [] chars
  where
    go : List Char -> List Char -> Maybe (List Char, List Char)
    go before [] = Nothing
    go before (char :: rest) =
      if char == needle
         then Just (reverse before, rest)
         else go (char :: before) rest

splitExponent : List Char -> Maybe (List Char, Maybe (List Char))
splitExponent chars = case splitOnce 'e' chars of
  Just (mantissa, exponent) =>
    if any (\char => char == 'e' || char == 'E') exponent
       then Nothing else Just (mantissa, Just exponent)
  Nothing => case splitOnce 'E' chars of
    Just (mantissa, exponent) =>
      if any (\char => char == 'e' || char == 'E') exponent
         then Nothing else Just (mantissa, Just exponent)
    Nothing => Just (chars, Nothing)

parseUnsigned : List Char -> Maybe Integer
parseUnsigned chars = if digitsOnly chars then Just (go 0 chars) else Nothing
  where
    digitValue : Char -> Integer
    digitValue char = cast (ord char - ord '0')

    go : Integer -> List Char -> Integer
    go accumulator [] = accumulator
    go accumulator (char :: rest) = go (accumulator * 10 + digitValue char) rest

parseExponent : List Char -> Maybe Integer
parseExponent [] = Nothing
parseExponent ('+' :: rest) = parseUnsigned rest
parseExponent ('-' :: rest) = map negate (parseUnsigned rest)
parseExponent rest = parseUnsigned rest

parseMantissa : List Char -> Maybe (Integer, Nat)
parseMantissa chars = case splitOnce '.' chars of
  Nothing => if validIntegerDigits chars
                then map (\value => (value, 0)) (parseUnsigned chars)
                else Nothing
  Just (whole, fraction) =>
    if validIntegerDigits whole && digitsOnly fraction
       then do
         value <- parseUnsigned (whole ++ fraction)
         Just (value, length fraction)
       else Nothing

applyExponent : Integer -> Nat -> Integer -> Decimal
applyExponent coefficient scale exponent =
  if exponent >= 0
     then let positive : Nat = cast exponent in
          if positive >= scale
             then MkDecimal (coefficient * pow10 (positive `minus` scale)) 0
             else MkDecimal coefficient (scale `minus` positive)
     else MkDecimal coefficient (scale + cast (negate exponent))

||| Parse exactly the LDML `number-literal` production: canonical integer
||| digits, optional non-empty fraction, and optional signed exponent.
public export
parseDecimal : String -> Maybe Decimal
parseDecimal source =
  let chars = unpack source
      (negative, unsigned) = case chars of
        '-' :: rest => (True, rest)
        _ => (False, chars) in
  do
    (mantissa, exponentChars) <- splitExponent unsigned
    (coefficient, scale) <- parseMantissa mantissa
    exponent <- case exponentChars of
      Nothing => Just 0
      Just chars => parseExponent chars
    let signed = if negative then negate coefficient else coefficient
    Just (normalize (applyExponent signed scale exponent))

repeatChar : Nat -> Char -> List Char
repeatChar Z char = []
repeatChar (S count) char = char :: repeatChar count char

takeList : Nat -> List value -> List value
takeList Z values = []
takeList (S count) [] = []
takeList (S count) (value :: rest) = value :: takeList count rest

dropList : Nat -> List value -> List value
dropList Z values = values
dropList (S count) [] = []
dropList (S count) (_ :: rest) = dropList count rest

padLeft : Nat -> List Char -> List Char
padLeft count chars = repeatChar count '0' ++ chars

renderScaled : List Char -> Nat -> String
renderScaled digits Z = pack digits
renderScaled digits scale =
  let count = length digits in
  if count > scale
     then let split = count `minus` scale
           in pack (takeList split digits) ++ "." ++ pack (dropList split digits)
     else "0." ++ pack (padLeft (scale `minus` count) digits)

||| Serialize a decimal without exponent notation. This is the exact numeric
||| key representation used by the reference matcher.
public export
renderDecimal : Decimal -> String
renderDecimal decimal =
  let decimal = normalize decimal
      negative = decimal.coefficient < 0
      digits = unpack (show (abs decimal.coefficient))
      rendered = renderScaled digits decimal.scale in
      if negative then "-" ++ rendered else rendered

public export
Show Decimal where
  show = renderDecimal

||| Discard the fractional component toward zero, matching `:integer`.
public export
truncateDecimal : Decimal -> Decimal
truncateDecimal decimal =
  let divisor = pow10 decimal.scale
      coefficient = if decimal.coefficient < 0
        then negate ((negate decimal.coefficient) `div` divisor)
        else decimal.coefficient `div` divisor in
      MkDecimal coefficient 0

||| Add an integer offset without leaving the exact-decimal domain.
public export
addWhole : Decimal -> Integer -> Decimal
addWhole decimal amount = normalize
  (MkDecimal (decimal.coefficient + amount * pow10 decimal.scale) decimal.scale)

||| Multiply by an integer without introducing binary floating-point error.
public export
multiplyWhole : Decimal -> Integer -> Decimal
multiplyWhole decimal amount = normalize
  (MkDecimal (decimal.coefficient * amount) decimal.scale)

||| True when the normalized value has no visible fraction.
public export
isIntegral : Decimal -> Bool
isIntegral decimal = (normalize decimal).scale == 0

||| Extract an integer only when no fractional value would be lost.
public export
wholeValue : Decimal -> Maybe Integer
wholeValue decimal =
  let decimal = normalize decimal in
  if decimal.scale == 0 then Just decimal.coefficient else Nothing
