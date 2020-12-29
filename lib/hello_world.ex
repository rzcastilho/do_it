defmodule HelloWorld do
  @moduledoc false

  use DoIt.Command,
    description: "Hello World Cliche"

  def run(_, _, _) do
    IO.puts("Hello World!!!")
  end

end
