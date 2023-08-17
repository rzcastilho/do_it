defmodule DoIt.Dispatcher do
  @moduledoc false

  @callback next(Map.t(), Map.t()) :: Map.t()
end
