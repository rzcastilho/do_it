defmodule HelloWorld.Template.Unset do
  use DoIt.Command,
    description: "Unset template"

  def run(_, _, _) do
    IO.puts("Unset template")
  end

end
