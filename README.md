[![Build Status](https://github.com/rzcastilho/do_it/workflows/CI/badge.svg)](https://github.com/rzcastilho/do_it/actions) [![Hex.pm](https://img.shields.io/hexpm/v/do_it.svg)](https://hex.pm/packages/do_it) [![Coverage Status](https://coveralls.io/repos/github/rzcastilho/do_it/badge.svg)](https://coveralls.io/github/rzcastilho/do_it) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/do_it/)

# Do It

Elixir Command Line Interface Framework.

A framework that helps to develop command line tools with Elixir.

## Installation

The package can be installed by adding `do_it` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:do_it, "~> 0.5.0"}
  ]
end
```

## Usage

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

```shell
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

It's the entrypoint of your CLI, it generates functions matching all declared commands in that module, delegating the call to the matched command.

A `MainCommand` could be defined as follows:

```elixir
defmodule Cli do
  use DoIt.MainCommand,
    description: "My useless CLI"

  command(Hello.Say)
  command(Hello.Config)

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

> #### Experimental {: .warning}
>
> See the elixir-burrito [readme](https://github.com/burrito-elixir/burrito) about some limitations and other configurations.

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
      {:burrito, github: "burrito-elixir/burrito"},
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

## License

DoIt is released under the Apache License 2.0 - see the [LICENSE](LICENSE) file.
