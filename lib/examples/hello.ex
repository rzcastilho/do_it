defmodule Hello do
  use DoIt.Command,
    description: "Hello command line tool",
    command: "olleh"

  param(:message, "Message", allowed_values: ["World", "Universe"])

  flag(:template, :string, "Template", alias: :t, default: "Hello <%= message %>!!!")
  flag(:"template-file", :string, "Template filename", alias: :f)

  def run([message], [template: template], _) do
    IO.puts EEx.eval_string(template, message: message)
  end

  def run([message], _, %{flags: %{template: %{default: template}}}) do
    IO.puts EEx.eval_string(template, message: message)
  end
end
