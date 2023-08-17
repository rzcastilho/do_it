defmodule HelloWorld.Say do
  use DoIt.Command,
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
