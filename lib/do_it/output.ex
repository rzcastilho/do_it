defmodule DoIt.Output do
  @moduledoc false

  alias DoIt.{Argument, Option}

  def greatest_name(list) do
    list
    |> Enum.map(fn %{name: name} -> "#{name}" end)
    |> Enum.max_by(&String.length/1)
    |> String.length()
  end

  def format_argument_name(%Argument{name: name}, align),
    do: "#{String.pad_trailing(Atom.to_string(name), align)}"

  def format_argument_description(%Argument{description: description}), do: description
  def format_argument_allowed_values(%Argument{allowed_values: nil}), do: ""

  def format_argument_allowed_values(%Argument{type: :string, allowed_values: allowed_values}),
    do: " (Allowed Values: \"#{Enum.join(allowed_values, "\", \"")}\")"

  def format_argument_allowed_values(%Argument{allowed_values: allowed_values}),
    do: " (Allowed Values: #{Enum.join(allowed_values, ", ")})"

  def format_option_alias(%Option{alias: nil}), do: "   "
  def format_option_alias(%Option{alias: alias}), do: "-#{Atom.to_string(alias)},"

  def format_option_name(%Option{name: name}, align),
    do:
      "--#{
        name
        |> Atom.to_string()
        |> String.replace("_", "-")
        |> String.pad_trailing(align)
      }"

  def format_option_description(%Option{description: description}), do: description
  def format_option_default(%Option{default: nil}), do: ""

  def format_option_default(%Option{type: :string, default: default}),
    do: " (Default: \"#{default}\")"

  def format_option_default(%Option{default: default}), do: " (Default: #{default})"
  def format_option_allowed_values(%Option{allowed_values: nil}), do: ""

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
    align = greatest_name(commands)

    for %{name: name, description: description} <- commands do
      IO.puts("  #{String.pad_trailing(name, align)}     #{description}")
    end

    IO.puts("")
  end

  def print_help(
        app: app,
        command: command,
        description: description,
        arguments: arguments,
        options: options
      ) do
    IO.puts("")

    IO.puts(
      "Usage: #{app} #{command}" <>
        "#{if Enum.empty?(options), do: " ", else: " [OPTIONS] "}" <>
        "#{
          arguments
          |> Enum.reverse()
          |> Enum.map(fn %{name: name} -> "<#{name}>" end)
          |> Enum.join(" ")
        }"
    )

    IO.puts("")

    IO.puts(description)
    IO.puts("")

    if !Enum.empty?(arguments) do
      align = greatest_name(arguments)
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
      align = greatest_name(options)
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
    IO.puts(
      "error(s):\n#{
        errors
        |> Enum.map(fn error -> "  * #{error}" end)
        |> Enum.join("\n")
      }"
    )
  end

  def print_errors(error), do: IO.puts(error)

  def print_invalid_options(command, invalid_options) do
    IO.puts(
      "invalid option(s) for command #{command}:\n#{
        invalid_options
        |> Enum.map(fn
          {option, nil} -> "  * #{option} without value"
          {option, value} -> "  * #{option} with #{value}"
        end)
        |> Enum.join("\n")
      }"
    )
  end
end
