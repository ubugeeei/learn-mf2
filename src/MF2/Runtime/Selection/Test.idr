module MF2.Runtime.Selection.Test

import MF2.Decimal
import MF2.Runtime.Selection
import MF2.Runtime.Types
import MF2.Syntax
import MF2.Testing

%default total

stringResolved : String -> ResolvedValue
stringResolved value = MkResolvedValue (StringValue value) value
  (StringSelection value) UnknownDirection False False

numberResolved : Decimal -> String -> String -> ResolvedValue
numberResolved decimal exact mode = MkResolvedValue (NumberValue decimal) exact
  (NumberSelection decimal exact mode) LTR False False

||| Unit tests for rank naming, locale rules, exact matching, and catch-all
||| behavior in the isolated selection phase.
public export
selectionTests : Results
selectionTests =
  let one = MkDecimal 1 0
      two = MkDecimal 2 0
      eleven = MkDecimal 11 0 in
  checkAll
    [ ("catch-all quality", matchQuality "en" (stringResolved "x") Catchall == CatchallMatch)
    , ("exact string quality", matchQuality "en" (stringResolved "x") (LiteralKey "x") == ExactMatch)
    , ("string no-match quality", matchQuality "en" (stringResolved "x") (LiteralKey "y") == NoMatch)
    , ("exact number quality", matchQuality "en" (numberResolved one "1" "plural") (LiteralKey "1") == ExactMatch)
    , ("plural rule quality", matchQuality "en" (numberResolved one "1" "plural") (LiteralKey "one") == RuleMatch)
    , ("plural rule no match", matchQuality "en" (numberResolved two "2" "plural") (LiteralKey "one") == NoMatch)
    , ("English cardinal one", pluralKeyword "en" "plural" one == "one")
    , ("English cardinal other", pluralKeyword "en-US" "plural" two == "other")
    , ("French zero is one", pluralKeyword "fr" "plural" (MkDecimal 0 0) == "one")
    , ("French one is one", pluralKeyword "fr-FR" "plural" one == "one")
    , ("French two is other", pluralKeyword "fr" "plural" two == "other")
    , ("Japanese cardinal other", pluralKeyword "ja" "plural" one == "other")
    , ("Chinese cardinal other", pluralKeyword "zh" "plural" one == "other")
    , ("Korean cardinal other", pluralKeyword "ko" "plural" one == "other")
    , ("English ordinal one", pluralKeyword "en" "ordinal" one == "one")
    , ("English ordinal two", pluralKeyword "en" "ordinal" two == "two")
    , ("English ordinal three", pluralKeyword "en" "ordinal" (MkDecimal 3 0) == "few")
    , ("English ordinal four", pluralKeyword "en" "ordinal" (MkDecimal 4 0) == "other")
    , ("English ordinal eleven", pluralKeyword "en" "ordinal" eleven == "other")
    , ("English ordinal twelve", pluralKeyword "en" "ordinal" (MkDecimal 12 0) == "other")
    , ("English ordinal thirteen", pluralKeyword "en" "ordinal" (MkDecimal 13 0) == "other")
    , ("English ordinal twenty-one", pluralKeyword "en" "ordinal" (MkDecimal 21 0) == "one")
    , ("fractional ordinal other", pluralKeyword "en" "ordinal" (MkDecimal 15 1) == "other")
    , ("exact mode has no keyword", pluralKeyword "en" "exact" one == "")
    ]
