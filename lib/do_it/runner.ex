defmodule DoIt.Runner do
  @moduledoc false

  @callback run(Map.t(), Map.t(), Map.t()) :: any()
end
