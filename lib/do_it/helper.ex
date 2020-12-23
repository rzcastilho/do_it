defmodule DoIt.Helper do
  @moduledoc false

  alias DoIt.{Flag, Param}

  def greatest_name(list) do
    list
    |> Enum.map(fn %{name: name} -> "#{name}" end)
    |> Enum.max_by(&String.length/1)
    |> String.length()
  end

  def format_param_name(%Param{name: name}, align), do: "#{String.pad_trailing(Atom.to_string(name), align)}"
  def format_param_description(%Param{description: description}), do: description
  def format_param_allowed_values(%Param{allowed_values: nil}), do: ""
  def format_param_allowed_values(%Param{allowed_values: allowed_values}), do: " - [Allowed Values: #{Enum.join(allowed_values, ", ")}]"

  def format_flag_alias(%Flag{alias: nil}), do: "   "
  def format_flag_alias(%Flag{alias: alias}), do: "-#{Atom.to_string(alias)},"
  def format_flag_name(%Flag{name: name}, align), do: "--#{String.pad_trailing(Atom.to_string(name), align)}"
  def format_flag_description(%Flag{description: description}), do: description
  def format_flag_default(%Flag{default: nil}), do: ""
  def format_flag_default(%Flag{default: default}), do: " - [Default: #{default}]"
  def format_flag_allowed_values(%Flag{allowed_values: nil}), do: ""
  def format_flag_allowed_values(%Flag{allowed_values: allowed_values}), do: " - [Allowed Values: #{Enum.join(allowed_values, ", ")}]"

  def print_help(app: app,
        command: command,
        description: description,
        params: params,
        flags: flags) do
    IO.puts "Usage: #{app} #{command}"
            <> "#{if Enum.empty?(flags), do: " ", else: " [FLAGS] "}"
            <> "#{params |> Enum.reverse |> Enum.map(fn %{name: name} -> "<#{name}>" end) |> Enum.join(" ")}"
    IO.puts ""

    IO.puts description
    IO.puts ""

    if !Enum.empty?(params)do
      align = greatest_name(params)
      IO.puts "Param(s):"
      for param <- Enum.reverse(params) do
        with name <- format_param_name(param, align),
             description <- format_param_description(param),
             allowed_values <- format_param_allowed_values(param) do
          IO.puts "  #{name} - #{description}#{allowed_values}"
        end
      end
      IO.puts ""
    end

    if !Enum.empty?(flags)do
      align = greatest_name(flags)
      IO.puts "Flag(s):"
      for flag <- Enum.reverse(flags) do
        with alias <- format_flag_alias(flag),
             name <- format_flag_name(flag, align),
             description <- format_flag_description(flag),
             default <- format_flag_default(flag),
             allowed_values <- format_flag_allowed_values(flag) do
          IO.puts "  #{alias} #{name} - #{description}#{default}#{allowed_values}"
        end
      end
      IO.puts ""
    end

  end

  def validate_list_type(list, type) do
    case type do
      :string -> Enum.all?(list, &is_binary/1)
      :integer -> Enum.all?(list, &is_integer/1)
      :float -> Enum.all?(list, &is_float/1)
    end
  end
end
