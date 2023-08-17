defmodule HelloWorld.Template.Set do
  use DoIt.Command,
    description: "Set template"

  argument(:content, :string, "Template content")

  def run(%{content: content}, _, _) do
    IO.puts("Set template:\n#{content}")
  end
end
