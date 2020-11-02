defmodule Hello do
  use DoIt.Command,
    description: "Hello to whom it may concern"

  flag :message, :string, "Message", alias: :m, required: true
  flag :template, :string, "Message template", alias: :t, default: "Hello <%= message %>!!!"

  def run([message: message, template: template], _) do
    EEx.eval_string(template, message: message)
  end

  def run([message: message], %{template: %{default: template}}) do
    EEx.eval_string(template, message: message)
  end

end
