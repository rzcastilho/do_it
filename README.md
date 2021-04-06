![CI](https://github.com/rzcastilho/do_it/workflows/CI/badge.svg)
![Coverage Status](https://coveralls.io/repos/github/rzcastilho/do_it/badge.svg)

# Do It

Elixir Command Line Interface Framework.

A framework that helps to develop command line tools with Elixir.

**_Do It_** have two main components:

  * `DoIt.Command` - represents a single command.
  * `DoIt.MainCommand` - find all defined commands in project and generate all functions to match all commands in a single module, must be used as `main_module` in `escript` definition.
  
The commands `version` and `help` are automatic generated for the client.

The version number is obtained from `mix.exs` or option `version` in `MainCommand`.

So, if you have a client named `cli`, you can type `cli version` and `cli help` to get the version number and the list of commands respectively from the client.

### Command

We can define a new command as follows:

```elixir
defmodule Hello do
  use DoIt.Command,
    description: "Useless hello command"

  argument(:message, :string, "Say hello to...")
  option(:template, :string, "Hello message template", alias: :t, default: "Hello <%= @message %>!!!")

  def run(%{message: message}, %{template: template}, _) do
    IO.puts EEx.eval_string(template, assigns: [message: message])
  end

end
```

A `help` option is automatically added to the command to describe its usage.

```shell script
$ ./cli hello --help

Usage: cli hello [OPTIONS] <message>

Useless hello command

Arguments:
  message   Hello nice message

Options:
      --help       Print this help
  -t, --template   Hello message template (Default: "Hello <%= @message %>!!!")
```

Use `DoIt.Command` and provide a required `description`, the command name is the module name, you can override that name using the `name` option.

```elixir
defmodule Hello do
  use DoIt.Command,
    name: "olleh",
    description: "Useless hello command"

  ...

end
```

### MainCommand

It generates functions matching all defined commands in the project, delegating the call to the matched command.

A `MainCommand` could be defined as follows:

```elixir
defmodule Cli do
  use DoIt.MainCommand,
    description: "My useless CLI"
end
```

## Installation

The package can be installed by adding `do_it` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:do_it, "~> 0.2.0"}
  ]
end
```

## License

DoIt is released under the Apache License 2.0 - see the [LICENSE](LICENSE) file.
