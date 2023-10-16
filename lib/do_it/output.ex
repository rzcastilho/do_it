defmodule DoIt.Output do
  @moduledoc """
  This module formats command help outputs.
  """

  alias DoIt.{Argument, Option}

  @doc """
  It gets the length of the longer name attribute.

  ## Examples

      iex> DoIt.Output.longer_name([%{name: "great"}, %{name: "greatest"}])
      8

      iex> DoIt.Output.longer_name([%{name: "Elixir"}, %{name: "Erlang"}, %{name: "DoIt"}, %{name: "OTP"}])
      6
  """
  def longer_name(list) do
    list
    |> Enum.map(fn %{name: name} -> "#{name}" end)
    |> Enum.max_by(&String.length/1)
    |> String.length()
  end

  @doc """
  It formats the given `DoIt.Argument` name attribute with spaces on the right, accordingly with the `align` parameter.

  ## Examples

      iex> DoIt.Output.format_argument_name(%DoIt.Argument{name: :verbose, type: :boolean, description: "Makes the command verbose"}, 15)
      "verbose        "
  """
  def format_argument_name(%Argument{name: name}, align),
    do: "#{String.pad_trailing(Atom.to_string(name), align)}"

  @doc """
  It returns the description from `DoIt.Argument`.

  ## Example

      iex> DoIt.Output.format_argument_description(%DoIt.Argument{name: :verbose, type: :boolean, description: "Makes the command verbose"})
      "Makes the command verbose"
  """
  def format_argument_description(%Argument{description: description}), do: description

  @doc """
  It returns the allowed values from the given `DoIt.Argument`.

  ## Examples

      iex> DoIt.Output.format_argument_allowed_values(%DoIt.Argument{name: :op, type: :string, description: "Operation", allowed_values: ["+", "-", "*", "/"]})
      " (Allowed Values: \\"+\\", \\"-\\", \\"*\\", \\"/\\")"

      iex> DoIt.Output.format_argument_allowed_values(%DoIt.Argument{name: :verbose, type: :boolean, description: "Makes the command verbose"})
      ""

      iex> DoIt.Output.format_argument_allowed_values(%DoIt.Argument{name: :number, type: :integer, description: "Numerical digit", allowed_values: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]})
      " (Allowed Values: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)"
  """
  def format_argument_allowed_values(%Argument{allowed_values: nil}), do: ""

  def format_argument_allowed_values(%Argument{type: :string, allowed_values: allowed_values}),
    do: " (Allowed Values: \"#{Enum.join(allowed_values, "\", \"")}\")"

  def format_argument_allowed_values(%Argument{allowed_values: allowed_values}),
    do: " (Allowed Values: #{Enum.join(allowed_values, ", ")})"

  @doc """
  It formats the given `DoIt.Option` alias attribute.

  ## Examples

      iex> DoIt.Output.format_option_alias(%DoIt.Option{name: :help, type: :boolean, description: "Shows the help command", alias: nil})
      "   "

      iex> DoIt.Output.format_option_alias(%DoIt.Option{name: :help, type: :boolean, description: "Shows the help command", alias: :h})
      "-h,"
  """
  def format_option_alias(%Option{alias: nil}), do: "   "
  def format_option_alias(%Option{alias: alias}), do: "-#{Atom.to_string(alias)},"

  @doc """
  It formats the given `DoIt.Option` name attribute with spaces on the right, accordingly with the `align` parameter.

  ## Examples

      iex> DoIt.Output.format_option_name(%DoIt.Option{name: :help, type: :boolean, description: "Shows the help command", alias: nil}, 10)
      "--help      "

      iex> DoIt.Output.format_option_name(%DoIt.Option{name: :log_level, type: :string, description: "Set the logging level", alias: nil}, 12)
      "--log-level   "
  """
  def format_option_name(%Option{name: name}, align),
    do: "--#{name |> Atom.to_string() |> String.replace("_", "-") |> String.pad_trailing(align)}"

  @doc """
  It returns the description from `DoIt.Option`.

  ## Examples

      iex> DoIt.Output.format_option_description(%DoIt.Option{name: :help, type: :boolean, description: "Shows the help command", alias: nil})
      "Shows the help command"
  """
  def format_option_description(%Option{description: description}), do: description

  @doc """
  It formats the given `DoIt.Option` default attribute.

  ## Examples

      iex> DoIt.Output.format_option_default(%DoIt.Option{name: :log_level, type: :string, description: "Set the logging level", alias: nil, default: "warn"})
      " (Default: \\"warn\\")"

      iex> DoIt.Output.format_option_default(%DoIt.Option{name: :skip_lines, type: :integer, description: "Lines to skip", alias: nil, default: 10})
      " (Default: 10)"

      iex> DoIt.Output.format_option_default(%DoIt.Option{name: :help, type: :boolean, description: "Shows the help command", alias: nil})
      ""
  """
  def format_option_default(%Option{default: nil}), do: ""

  def format_option_default(%Option{type: :string, default: default}),
    do: " (Default: \"#{default}\")"

  def format_option_default(%Option{default: default}), do: " (Default: #{default})"
  def format_option_allowed_values(%Option{allowed_values: nil}), do: ""

  @doc """
  It returns the allowed values from the given `DoIt.Option`.

  ## Examples

      iex> DoIt.Output.format_option_allowed_values(%DoIt.Option{name: :op, type: :string, description: "Operation", allowed_values: ["+", "-", "*", "/"]})
      " (Allowed Values: \\"+\\", \\"-\\", \\"*\\", \\"/\\")"

      iex> DoIt.Output.format_option_allowed_values(%DoIt.Option{name: :verbose, type: :boolean, description: "Makes the command verbose"})
      ""

      iex> DoIt.Output.format_option_allowed_values(%DoIt.Option{name: :number, type: :integer, description: "Numerical digit", allowed_values: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]})
      " (Allowed Values: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)"
  """
  def format_option_allowed_values(%Option{type: :string, allowed_values: allowed_values}),
    do: " (Allowed Values: \"#{Enum.join(allowed_values, "\", \"")}\")"

  def format_option_allowed_values(%Option{allowed_values: allowed_values}),
    do: " (Allowed Values: #{Enum.join(allowed_values, ", ")})"

  def print_help(
        app: app,
        commands: commands,
        main_description: main_description
      ) do
    IO.puts("")

    IO.puts("Usage: #{app} COMMAND")
    IO.puts("")

    IO.puts(main_description)
    IO.puts("")

    IO.puts("Commands:")
    align = longer_name(commands)

    for %{name: name, description: description} <- commands do
      IO.puts("  #{String.pad_trailing(name, align)}     #{description}")
    end

    IO.puts("")

    IO.puts("Run '#{app} COMMAND --help' for more information on a command.")
    IO.puts("")
  end

  def print_help(
        commands: commands,
        description: description,
        subcommands: subcommands
      ) do
    commands_stringify =
      commands
      |> Enum.map(& &1.command)
      |> Enum.map_join(" ", &elem(&1, 0))

    IO.puts("")

    IO.puts("Usage: #{commands_stringify} SUBCOMMAND")
    IO.puts("")

    IO.puts(description)
    IO.puts("")

    IO.puts("Subcommands:")
    align = longer_name(subcommands)

    for %{name: name, description: description} <- subcommands do
      IO.puts("  #{String.pad_trailing(name, align)}     #{description}")
    end

    IO.puts("")

    IO.puts("Run '#{commands_stringify} SUBCOMMAND --help' for more information on a subcommand.")
    IO.puts("")
  end

  def print_help(
        commands: commands,
        description: description,
        arguments: arguments,
        options: options
      ) do
    commands_stringify =
      commands
      |> Enum.map(& &1.command)
      |> Enum.map_join(" ", &elem(&1, 0))

    IO.puts("")

    IO.puts(
      "Usage: #{commands_stringify}" <>
        "#{if Enum.empty?(options), do: " ", else: " [OPTIONS] "}" <>
        "#{arguments |> Enum.reverse() |> Enum.map_join(" ", fn %{name: name} -> "<#{name}>" end)}"
    )

    IO.puts("")

    IO.puts(description)
    IO.puts("")

    if !Enum.empty?(arguments) do
      align = longer_name(arguments)
      IO.puts("Arguments:")

      for argument <- Enum.reverse(arguments) do
        with name <- format_argument_name(argument, align),
             description <- format_argument_description(argument),
             allowed_values <- format_argument_allowed_values(argument) do
          IO.puts("  #{name}   #{description}#{allowed_values}")
        end
      end

      IO.puts("")
    end

    if !Enum.empty?(options) do
      align = longer_name(options)
      IO.puts("Options:")

      for option <- Enum.reverse(options) do
        with alias <- format_option_alias(option),
             name <- format_option_name(option, align),
             description <- format_option_description(option),
             default <- format_option_default(option),
             allowed_values <- format_option_allowed_values(option) do
          IO.puts("  #{alias} #{name}   #{description}#{default}#{allowed_values}")
        end
      end

      IO.puts("")
    end
  end

  def print_errors(errors) when is_list(errors) do
    IO.puts("error(s):\n#{errors |> Enum.map_join("\n", fn error -> "  * #{error}" end)}")
  end

  def print_errors(error), do: IO.puts(error)

  def print_invalid_options(command, invalid_options) do
    IO.puts(
      "invalid option(s) for command #{command}:\n#{invalid_options |> Enum.map_join("\n", fn
        {option, nil} -> "  * #{option} without value"
        {option, value} -> "  * #{option} with #{value}"
      end)}"
    )
  end
end
