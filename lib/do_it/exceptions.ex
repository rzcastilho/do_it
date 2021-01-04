defmodule DoIt.MainCommandDefinitionError do
  @moduledoc """
  It shows a problem with the main command definition.
  """
  defexception [:message]
end

defmodule DoIt.CommandDefinitionError do
  @moduledoc """
  It shows a problem with a command definition.
  """
  defexception [:message]
end

defmodule DoIt.ArgumentDefinitionError do
  @moduledoc """
  It shows a problem with an argument definition.
  """
  defexception [:message]
end

defmodule DoIt.OptionDefinitionError do
  @moduledoc """
  It shows a problem with an option definition.
  """
  defexception [:message]
end
