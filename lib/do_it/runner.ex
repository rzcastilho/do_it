defmodule DoIt.Runner do
  @moduledoc false

  @callback run(List.t(), List.t(), Map.t()) :: any()
end
