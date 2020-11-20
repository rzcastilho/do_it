defmodule DoIt.Helper do
  @moduledoc false

  defp greatest_key(list) do
    list
    |> Enum.map(fn {key, _} -> "#{key}" end)
    |> Enum.max_by(&String.length/1)
    |> String.length()
  end

  def formated_params_list([]), do: ""

  def formated_params_list(params) do
    align = greatest_key(params)

    "Params:\n\n" <>
      (params
       |> Enum.reverse()
       |> Enum.map(fn {name, %{description: description}} ->
         "  #{String.pad_trailing(Atom.to_string(name), align)} - #{description}"
       end)
       |> Enum.join("\n"))
  end

  def formated_flags_list([]), do: ""

  def formated_flags_list(flags) do
    align = greatest_key(flags)

    "Flags:\n\n" <>
      (flags
       |> Enum.reverse()
       |> Enum.map(fn
         {name, %{description: description, required: true, alias: nil}} ->
           "      --#{String.pad_trailing(Atom.to_string(name), align)} - #{description} [required]"

         {name, %{description: description, alias: nil}} ->
           "      --#{String.pad_trailing(Atom.to_string(name), align)} - #{description}"

         {name, %{description: description, required: true, alias: alias}} ->
           "  -#{Atom.to_string(alias)}, --#{String.pad_trailing(Atom.to_string(name), align)} - #{
             description
           } [required]"

         {name, %{description: description, alias: alias}} ->
           "  -#{Atom.to_string(alias)}, --#{String.pad_trailing(Atom.to_string(name), align)} - #{
             description
           }"
       end)
       |> Enum.join("\n"))
  end

  def validate_params(params, parsed_params) do
  end
end
