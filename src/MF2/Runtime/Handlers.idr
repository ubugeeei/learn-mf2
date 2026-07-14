module MF2.Runtime.Handlers

import MF2.Diagnostic
import MF2.Runtime.Handlers.Measure
import MF2.Runtime.Handlers.Numeric
import MF2.Runtime.Handlers.Text
import MF2.Runtime.Types
import MF2.Syntax

%default total

||| Find an application-defined handler by its fully qualified identifier.
export
findCustom : Identifier -> Registry -> Maybe FunctionHandler
findCustom identifier [] = Nothing
findCustom identifier ((candidate, handler) :: rest) =
  if identifier == candidate then Just handler else findCustom identifier rest

||| Map a stable 48.2 function name to its small, independently tested module.
defaultHandler : String -> Maybe DefaultHandler
defaultHandler "string" = Just stringHandler
defaultHandler "number" = Just (numberHandler False)
defaultHandler "integer" = Just (numberHandler True)
defaultHandler "offset" = Just offsetHandler
defaultHandler "percent" = Just percentHandler
defaultHandler "currency" = Just currencyHandler
defaultHandler "unit" = Just unitHandler
defaultHandler "datetime" = Just (temporalHandler "datetime")
defaultHandler "date" = Just (temporalHandler "date")
defaultHandler "time" = Just (temporalHandler "time")
defaultHandler _ = Nothing

||| Invoke a built-in function when its identifier is unnamespaced and known.
|||
||| `Nothing` means dispatch did not recognize the name; a recognized handler
||| failure remains `Just (Left diagnostic)` so resolution can distinguish an
||| unknown function from a message-function error.
public export
runDefault : FunctionContext -> FunctionRef -> Maybe Value -> Options
          -> Maybe HandlerResult
runDefault context function operand options = case function.name.scope of
  Just _ => Nothing
  Nothing => map
    (\handler => handler context function.span operand options)
    (defaultHandler function.name.name)
