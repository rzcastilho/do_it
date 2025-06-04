defmodule DoIt.Runner do
  @moduledoc false

  @callback run(map(), map(), map()) :: any()
end
