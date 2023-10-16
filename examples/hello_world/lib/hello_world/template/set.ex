defmodule HelloWorld.Template.Set do
  use DoIt.Command,
    description: "Set default message template"

  argument(:content, :string, "Template content")

  def run(%{content: content}, _, _) do
    DoIt.Commfig.set("default_template", content)
  end
end
