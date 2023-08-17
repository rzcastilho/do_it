defmodule HelloWorld.Template.Default do
  use DoIt.Command,
    description: "Set default template"

  @default_template "Hello <%= @message %>!!!"

  def run(_, _, _) do
    IO.puts("Set default template:\n#{@default_template}")
  end
end
