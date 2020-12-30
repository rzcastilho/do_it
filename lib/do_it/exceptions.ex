defmodule DoIt.MainCommandDefinitionError do
  defexception [:message]
end

defmodule DoIt.CommandDefinitionError do
  defexception [:message]
end

defmodule DoIt.ArgumentDefinitionError do
  defexception [:message]
end

defmodule DoIt.OptionDefinitionError do
  defexception [:message]
end
