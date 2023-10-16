defmodule DoIt.OutputTest do
  @moduledoc false
  use ExUnit.Case

  alias DoIt.{
    Argument,
    Option,
    Output
  }

  import ExUnit.CaptureIO
  doctest DoIt.Output

  defmodule Hello do
    def command(), do: {"hello", "Hello World CLI"}
  end

  defmodule Template do
    def command(), do: {"template", "Manage HelloWorld Template"}
  end

  defmodule Say do
    def command(), do: {"say", "Say something!!!"}
  end

  test "successfully prints list of errors" do
    assert capture_io(fn ->
             Output.print_errors(["invalid input value", "input is not assignable to integer"])
           end) == """
           error(s):
             * invalid input value
             * input is not assignable to integer
           """
  end

  test "successfully prints error" do
    assert capture_io(fn ->
             Output.print_errors("invalid input value")
           end) == "invalid input value\n"
  end

  test "successfully prints invalid options" do
    assert capture_io(fn ->
             Output.print_invalid_options("say", [{"--template", nil}, {"--count", "two"}])
           end) == """
           invalid option(s) for command say:
             * --template without value
             * --count with two
           """
  end

  test "successfully prints main command help" do
    assert capture_io(fn ->
             Output.print_help(
               app: "hello",
               commands: [
                 %{name: "template", description: "Manage HelloWorld Template"},
                 %{name: "say", description: "Say something!!!"}
               ],
               main_description: "Hello World CLI"
             )
           end) == """

           Usage: hello COMMAND

           Hello World CLI

           Commands:
             template     Manage HelloWorld Template
             say          Say something!!!

           Run 'hello COMMAND --help' for more information on a command.

           """
  end

  test "successfully prints parent command help" do
    assert capture_io(fn ->
             Output.print_help(
               commands: [Hello, Template],
               description: "Manage HelloWorld default template",
               subcommands: [
                 %{name: "show", description: "Show default template"},
                 %{name: "unset", description: "Remove default template"},
                 %{name: "set", description: "Set default template"}
               ]
             )
           end) == """

           Usage: hello template SUBCOMMAND

           Manage HelloWorld default template

           Subcommands:
             show      Show default template
             unset     Remove default template
             set       Set default template

           Run 'hello template SUBCOMMAND --help' for more information on a subcommand.

           """
  end

  test "successfully prints command help" do
    assert capture_io(fn ->
             Output.print_help(
               commands: [Hello, Say],
               description: "Say something!!!",
               arguments: [
                 %Argument{name: :message, type: :string, description: "Hello message"}
               ],
               options: [
                 %Option{
                   name: :template,
                   alias: :t,
                   type: :string,
                   description: "Message template"
                 },
                 %Option{name: :help, type: :boolean, description: "Print this help"}
               ]
             )
           end) == """

           Usage: hello say [OPTIONS] <message>

           Say something!!!

           Arguments:
             message   Hello message

           Options:
                 --help       Print this help
             -t, --template   Message template

           """
  end
end
