defmodule HelloWorld.Template.Show do
  use DoIt.Command,
    description: "Show default message template"

  def run(_, _, %{config: %{"default_template" => template}}) do
    IO.puts("Default template:\n#{template}")
  end

  def run(_, _, _), do: IO.puts("The default template was not defined!")
end
