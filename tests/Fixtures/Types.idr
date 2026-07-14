module Fixtures.Types

%default total

||| A source string copied from the Unicode MessageFormat Working Group's
||| LDML48.2 conformance snapshot.
public export
record Fixture where
  constructor MkFixture
  description : String
  source : String

||| A source string paired with its first expected data-model error category.
public export
record ErrorFixture where
  constructor MkErrorFixture
  description : String
  source : String
  expected : String
