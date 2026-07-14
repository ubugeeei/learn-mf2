module MF2.Diagnostic

%default total

||| A half-open source range measured in Unicode code points.
||| Offsets deliberately do not use UTF-8 bytes, so diagnostics agree with the
||| grammar's code-point-based character classes.
public export
record Span where
  constructor MkSpan
  start : Nat
  end : Nat

public export
Show Span where
  show span = show span.start ++ ".." ++ show span.end

||| Stable diagnostic categories used at the parser, validator, and runtime
||| boundaries. The names mirror LDML Part 9's error taxonomy.
public export
data ErrorKind
  = SyntaxError
  | VariantKeyMismatch
  | MissingFallbackVariant
  | MissingSelectorAnnotation
  | DuplicateDeclaration
  | DuplicateOptionName
  | DuplicateVariant
  | UnresolvedVariable
  | UnknownFunction
  | BadSelector
  | BadOperand
  | BadOption
  | BadVariantKey
  | UnsupportedOperation

public export
Eq ErrorKind where
  SyntaxError == SyntaxError = True
  VariantKeyMismatch == VariantKeyMismatch = True
  MissingFallbackVariant == MissingFallbackVariant = True
  MissingSelectorAnnotation == MissingSelectorAnnotation = True
  DuplicateDeclaration == DuplicateDeclaration = True
  DuplicateOptionName == DuplicateOptionName = True
  DuplicateVariant == DuplicateVariant = True
  UnresolvedVariable == UnresolvedVariable = True
  UnknownFunction == UnknownFunction = True
  BadSelector == BadSelector = True
  BadOperand == BadOperand = True
  BadOption == BadOption = True
  BadVariantKey == BadVariantKey = True
  UnsupportedOperation == UnsupportedOperation = True
  _ == _ = False

public export
Show ErrorKind where
  show SyntaxError = "syntax-error"
  show VariantKeyMismatch = "variant-key-mismatch"
  show MissingFallbackVariant = "missing-fallback-variant"
  show MissingSelectorAnnotation = "missing-selector-annotation"
  show DuplicateDeclaration = "duplicate-declaration"
  show DuplicateOptionName = "duplicate-option-name"
  show DuplicateVariant = "duplicate-variant"
  show UnresolvedVariable = "unresolved-variable"
  show UnknownFunction = "unknown-function"
  show BadSelector = "bad-selector"
  show BadOperand = "bad-operand"
  show BadOption = "bad-option"
  show BadVariantKey = "bad-variant-key"
  show UnsupportedOperation = "unsupported-operation"

||| A compiler diagnostic with a category, precise source range, and an
||| actionable explanation. Multiple data-model errors may be accumulated.
public export
record Diagnostic where
  constructor MkDiagnostic
  kind : ErrorKind
  span : Span
  message : String

public export
Show Diagnostic where
  show diagnostic = show diagnostic.kind ++ " at " ++ show diagnostic.span
                 ++ ": " ++ diagnostic.message

||| Create a point diagnostic at the current parser offset.
public export
point : ErrorKind -> Nat -> String -> Diagnostic
point kind offset message = MkDiagnostic kind (MkSpan offset offset) message

