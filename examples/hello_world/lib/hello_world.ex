defmodule HelloWorld do
  use DoIt.Command,
    command: "say",
    description: "Useless hello command"

  argument(:message, :string, "Say hello to...")

  option(:template, :string, "Hello message template",
    alias: :t,
    default: "Hello <%= @message %>!!!"
  )

  def run(%{message: message}, %{template: template}, _) do
    IO.puts(EEx.eval_string(template, assigns: [message: message]))
  end
end
