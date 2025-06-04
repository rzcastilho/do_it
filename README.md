[![Build Status](https://github.com/rzcastilho/do_it/workflows/CI/badge.svg)](https://github.com/rzcastilho/do_it/actions) [![Hex.pm](https://img.shields.io/hexpm/v/do_it.svg)](https://hex.pm/packages/do_it) [![Coverage Status](https://coveralls.io/repos/github/rzcastilho/do_it/badge.svg)](https://coveralls.io/github/rzcastilho/do_it) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/do_it/)

# Do It

Elixir Command Line Interface Library.

A library that helps to develop CLI tools with Elixir.

## Installation

The package can be installed by adding `do_it` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:do_it, "~> 0.7"}
  ]
end
```

## Usage

**_Do It_** have two main components:

  * `DoIt.Command` - represents a single command.
  * `DoIt.MainCommand` - the entrypoint of the application where you declare all the commands, must be used as `main_module` in `escript` definition.

The commands `version` and `help` are automatic generated for the client.

The version number is obtained from `mix.exs` or option `version` in `MainCommand`.

So, if you have a client named `cli`, you can type `cli version` and `cli help` to get the version number and the list of commands respectively from the client.

### MainCommand

It's the entrypoint of your CLI, it generates functions matching all declared commands in that module, delegating the call to the matched command.

A `MainCommand` could be defined as follows:

```elixir
defmodule HelloWorld do
  use DoIt.MainCommand,
    description: "HelloWorld CLI"

  command(HelloWorld.Say)
  command(HelloWorld.Template)
end
```

### Command

We can define a new command as follows:

```elixir
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

```

A `help` option is automatically added to the command to describe its usage.

```shell
$ ./hello_world say --help

Usage: hello_world say [OPTIONS] <message>

Say something!!!

Arguments:
  message   Hello message

Options:
      --help       Print this help
  -t, --template   Message template
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

You can declare subcommands in a command to group them logically using the `subcommand` macro.

```elixir
defmodule HelloWorld.Template do
  use DoIt.Command,
    description: "Manage HelloWorld Template"

  subcommand(HelloWorld.Template.Set)
  subcommand(HelloWorld.Template.Unset)
  subcommand(HelloWorld.Template.Show)
end
```

## Package

There are two ways to generate the binaries.

- [escript](https://hexdocs.pm/mix/Mix.Tasks.Escript.Build.html)
- [burrito-elixir](https://github.com/burrito-elixir/burrito)

### escript

To generate an application using the escript, you have to add a `:escript` key with the `:main_module` option to your project properties in your `mix.exs` file.

The `:main_module` is the module that you defined as `DoIt.MainCommand`.

```elixir
...
  def project do
    [
      app: :hello_world,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Cli]
    ]
  end
...
```

Build the binary running the mix task bellow.

```shell
$ mix escript.build
==> do_it
Compiling 4 files (.ex)
Generated do_it app
==> hello_world
Compiling 1 file (.ex)
Generated escript hello_world with MIX_ENV=dev
```

A binary with the application name will be generated in the project root.

```shell
$ ./hello_world help                                                                                                                                                     ─╯

Usage: hello_world COMMAND

My useless CLI

Commands:
  say     Useless hello command
```

### burrito-elixir

To configure the application to use the `burrito-elixir` you have to add the `burrito-elixir` dependency in your project, add the `:mod` property in the `application` function, and the `:releases` key with the releases configuration to your project properties in you `mix.exs` file.

The `:mod` property value is the module that you defined as `DoIt.MainCommand`.

```elixir
defmodule CoinGeckoCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :coin_gecko_cli,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CoinGeckoCli, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:do_it, "~> 0.4"},
      {:burrito, "~> 1.3"},
      {:tableize, "~> 0.1.0"}
    ]
  end

  def releases do
    [
      coin_gecko_cli: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos: [os: :darwin, cpu: :x86_64],
            linux: [os: :linux, cpu: :x86_64],
            windows: [os: :windows, cpu: :x86_64]
          ],
        ]
      ]
    ]
  end
end
```

Generate the binaries using the mix task bellow, a binary of each target will be generated in the `burrito_out` folder of your root application.

```shell
$ MIX_ENV=prod mix release
...
...
...
$ cd burrito_out
$ ls -c1                                                                                                                                                                 ─╯
coin_gecko_cli_linux
coin_gecko_cli_macos
coin_gecko_cli_windows

$ ./coin_gecko_cli_linux help                                                                                                                                            ─╯

Usage: coin_gecko_cli COMMAND

CoinGecko CLI

Commands:
  list     List assets
```

## Auto-completion

**_Do It_** provides comprehensive shell auto-completion support for bash, fish, and zsh shells. Auto-completion helps users discover available commands, subcommands, and options without needing to remember the exact syntax.

### Features

- **Command completion**: Complete command and subcommand names
- **Option completion**: Complete option flags (`--help`, `-v`, etc.)
- **Value completion**: Complete option values when allowed values are defined
- **Context-aware**: Completions are context-sensitive based on the current command path
- **Multi-shell support**: Generate completion scripts for bash, fish, and zsh

### Built-in Completion Commands

Every Do It CLI automatically includes completion commands:

```shell
# Generate completion script for bash
your_cli completion bash

# Generate completion script for fish
your_cli completion fish

# Generate completion script for zsh
your_cli completion zsh

# Show installation instructions
your_cli completion install bash

# Internal completion command (used by shell scripts)
your_cli completion complete <args>

# Debug completion information
your_cli completion debug
```

### Installation

#### Bash

Add to your `~/.bashrc`:
```bash
eval "$(your_cli completion bash)"
```

Or install system-wide:
```bash
your_cli completion bash | sudo tee /etc/bash_completion.d/your_cli
```

#### Fish

Install completion script:
```bash
your_cli completion fish > ~/.config/fish/completions/your_cli.fish
```

#### Zsh

Add to your `~/.zshrc`:
```bash
eval "$(your_cli completion zsh)"
```

Make sure you have completion system initialized:
```bash
autoload -U compinit
compinit
```

### Using Mix Task

You can also generate completion scripts during development:

```bash
# Generate bash completion to stdout
mix do_it.gen.completion --shell bash

# Generate fish completion and save to file
mix do_it.gen.completion --shell fish --output ~/.config/fish/completions/myapp.fish

# Show installation instructions
mix do_it.gen.completion --shell zsh --install

# Specify main module explicitly
mix do_it.gen.completion --shell bash --main-module MyApp.CLI
```

### Enhanced Option Support

You can enhance option completion by specifying allowed values:

```elixir
defmodule MyApp.Deploy do
  use DoIt.Command,
    description: "Deploy application"

  option(:environment, :string, "Target environment",
    allowed_values: ["dev", "staging", "prod"])

  option(:format, :string, "Output format",
    allowed_values: ["json", "yaml", "table"])

  def run(_args, _opts, _context), do: :ok
end
```

With this setup, typing `myapp deploy --environment <TAB>` will complete with `dev`, `staging`, or `prod`.

## License

Do It is released under the Apache License 2.0 - see the [LICENSE](LICENSE) file.
