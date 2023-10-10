defmodule HelloWorld.Say do
  use DoIt.Command,
    description: "Say something!!!"

  argument(:message, :string, "Hello message")

  option(:template, :string, "Message template", alias: :t)

  def run(%{message: message}, %{template: template}, _) do
    hello(message, template)
  end

  def run(%{message: message}, _, %{config: %{"default_template" => template}}) do
    hello(message, template)
  end

  def run(_, _, context) do
    IO.puts("Pass a template s parameter or define a default template using template set command")
    help(context)
  end

  defp hello(message, template) do
    IO.puts(EEx.eval_string(template, assigns: [message: message]))
  end
end
