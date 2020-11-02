defmodule DoIt.Runner do
  @moduledoc false

  @callback run(List.t, Map.t) :: boolean()

end
