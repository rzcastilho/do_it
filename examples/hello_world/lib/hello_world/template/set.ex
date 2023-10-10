defmodule HelloWorld.Template.Set do
  use DoIt.Command,
    description: "Set message template"

  argument(:content, :string, "Template content")

  def run(%{content: content}, _, context) do
    IO.inspect(context)
    DoIt.Commfig.set("default_template", content)
  end
end
