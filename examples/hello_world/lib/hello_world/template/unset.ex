defmodule HelloWorld.Template.Unset do
  use DoIt.Command,
    description: "Remove default message  template"

  def run(_, _, context) do
    IO.inspect(context)
    DoIt.Commfig.unset("default_template")
  end
end
