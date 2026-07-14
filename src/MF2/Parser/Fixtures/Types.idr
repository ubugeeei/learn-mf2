module MF2.Parser.Fixtures.Types

%default total

||| A source string copied from the Unicode MessageFormat Working Group's
||| LDML48.2 conformance snapshot.
public export
record Fixture where
  constructor MkFixture
  description : String
  source : String
