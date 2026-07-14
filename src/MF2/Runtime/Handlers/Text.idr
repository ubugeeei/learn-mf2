module MF2.Runtime.Handlers.Text

import MF2.Diagnostic
import MF2.Runtime.Environment
import MF2.Runtime.Types

%default total

||| Implement `:string` with exact-string selection capability.
export
stringHandler : DefaultHandler
stringHandler _ span Nothing options =
  Left (runtimeDiagnostic BadOperand span ":string requires an operand")
stringHandler _ span (Just (FallbackValue _)) options =
  Left (runtimeDiagnostic BadOperand span ":string received a fallback operand")
stringHandler _ span (Just value) options =
  let rendered = rawString value
      resolved = MkResolvedValue (StringValue rendered) rendered
                   (StringSelection rendered) UnknownDirection False False in
      Right (withDirection options resolved)

temporalValue : String -> String -> Value
temporalValue "date" = DateValue
temporalValue "time" = TimeValue
temporalValue _ = DateTimeValue

temporalSource : Value -> Maybe String
temporalSource (StringValue source) = Just source
temporalSource (DateValue source) = Just source
temporalSource (TimeValue source) = Just source
temporalSource (DateTimeValue source) = Just source
temporalSource _ = Nothing

||| Implement the locale-backend seam shared by `:date`, `:time`, and
||| `:datetime`. The reference backend preserves the temporal source text.
export
temporalHandler : String -> DefaultHandler
temporalHandler kind _ span Nothing options =
  Left (runtimeDiagnostic BadOperand span (":" ++ kind ++ " requires an operand"))
temporalHandler kind _ span (Just value) options = case temporalSource value of
  Nothing => Left (runtimeDiagnostic BadOperand span
             (":" ++ kind ++ " requires a temporal or string operand"))
  Just source => Right (withDirection options
    (MkResolvedValue (temporalValue kind source) source NoSelection LTR False False))
