defmodule DoIt.MainCommandDefinitionError do
  defexception [:message]
end

defmodule DoIt.CommandDefinitionError do
  defexception [:message]
end

defmodule DoIt.FlagDefinitionError do
  defexception [:message]
end

defmodule DoIt.ParamDefinitionError do
  defexception [:message]
end
