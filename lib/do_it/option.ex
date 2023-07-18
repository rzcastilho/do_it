defmodule DoIt.Option do
  @moduledoc false

  import DoIt.Helper, only: [validate_list_type: 2]

  @option_types [:boolean, :count, :integer, :float, :string]

  @type t :: %__MODULE__{
          name: atom,
          type: atom,
          description: String.t(),
          alias: atom,
          default: String.t() | integer | float | boolean,
          keep: boolean,
          allowed_values: list
        }
  @enforce_keys [:name, :type, :description]
  defstruct [:name, :type, :description, :alias, :default, :keep, :allowed_values]

  def validate_definition(%DoIt.Option{} = option) do
    option
    |> validate_definition_name
    |> validate_definition_type
    |> validate_definition_description
    |> validate_definition_alias
    |> validate_definition_keep
    |> validate_definition_allowed_values
    |> validate_definition_default
  end

  def validate_definition_name(%DoIt.Option{name: nil}),
    do: raise(DoIt.OptionDefinitionError, message: "name is required for option definition")

  def validate_definition_name(%DoIt.Option{name: name} = option) when is_atom(name), do: option

  def validate_definition_name(%DoIt.Option{name: _}),
    do: raise(DoIt.OptionDefinitionError, message: "name must be an atom")

  def validate_definition_type(%DoIt.Option{type: nil}),
    do: raise(DoIt.OptionDefinitionError, message: "type is required for option definition")

  def validate_definition_type(%DoIt.Option{type: type} = option) when type in @option_types,
    do: option

  def validate_definition_type(%DoIt.Option{type: type}),
    do:
      raise(DoIt.OptionDefinitionError,
        message:
          "unrecognized option type '#{type}', allowed types are #{@option_types |> Enum.map_join(", ", &Atom.to_string/1)}"
      )

  def validate_definition_description(%DoIt.Option{description: nil}),
    do:
      raise(DoIt.OptionDefinitionError, message: "description is required for option definition")

  def validate_definition_description(%DoIt.Option{description: description} = option)
      when is_binary(description),
      do: option

  def validate_definition_description(%DoIt.Option{description: _}),
    do: raise(DoIt.OptionDefinitionError, message: "description must be a string")

  def validate_definition_alias(%DoIt.Option{alias: nil} = option), do: option

  def validate_definition_alias(%DoIt.Option{alias: alias} = option) when is_atom(alias),
    do: option

  def validate_definition_alias(%DoIt.Option{alias: _}),
    do: raise(DoIt.OptionDefinitionError, message: "alias must be an atom")

  def validate_definition_keep(%DoIt.Option{keep: nil} = option), do: option

  def validate_definition_keep(%DoIt.Option{type: :count, keep: _}),
    do: raise(DoIt.OptionDefinitionError, message: "keep cannot be used with type count")

  def validate_definition_keep(%DoIt.Option{keep: keep} = option) when is_boolean(keep),
    do: option

  def validate_definition_keep(%DoIt.Option{keep: _}),
    do: raise(DoIt.OptionDefinitionError, message: "keep must be a boolean")

  def validate_definition_allowed_values(%DoIt.Option{allowed_values: nil} = option), do: option

  def validate_definition_allowed_values(%DoIt.Option{type: type, allowed_values: _})
      when type in [:boolean, :count],
      do:
        raise(DoIt.OptionDefinitionError,
          message: "allowed_values cannot be used with types boolean and count"
        )

  def validate_definition_allowed_values(
        %DoIt.Option{type: type, allowed_values: allowed_values} = option
      )
      when is_list(allowed_values) do
    case validate_list_type(allowed_values, type) do
      true ->
        option

      _ ->
        raise DoIt.OptionDefinitionError,
          message: "all values in allowed_values must be of type #{Atom.to_string(type)}"
    end
  end

  def validate_definition_allowed_values(%DoIt.Option{allowed_values: _}),
    do: raise(DoIt.OptionDefinitionError, message: "allowed_values must be a list")

  def validate_definition_default(%DoIt.Option{default: nil} = option), do: option

  def validate_definition_default(
        %DoIt.Option{type: :string, default: default, allowed_values: nil} = option
      )
      when is_binary(default),
      do: option

  def validate_definition_default(
        %DoIt.Option{type: :integer, default: default, allowed_values: nil} = option
      )
      when is_integer(default),
      do: option

  def validate_definition_default(
        %DoIt.Option{type: :float, default: default, allowed_values: nil} = option
      )
      when is_float(default),
      do: option

  def validate_definition_default(
        %DoIt.Option{type: :boolean, default: default, allowed_values: nil} = option
      )
      when is_boolean(default),
      do: option

  def validate_definition_default(
        %DoIt.Option{type: :count, default: default, allowed_values: nil} = option
      )
      when is_integer(default),
      do: option

  def validate_definition_default(%DoIt.Option{type: type, default: _, allowed_values: nil}),
    do:
      raise(DoIt.OptionDefinitionError,
        message: "default value must be of type #{Atom.to_string(type)}"
      )

  def validate_definition_default(
        %DoIt.Option{default: default, allowed_values: allowed_values} = option
      ) do
    case default in allowed_values do
      true ->
        option

      _ ->
        raise DoIt.OptionDefinitionError,
          message: "default value must be included in allowed_values"
    end
  end

  def parse_input(options, parsed) do
    {
      :ok,
      options
      |> default(parsed)
      |> group()
    }
  end

  def default(options, parsed) do
    options
    |> Enum.filter(&default_filter/1)
    |> Enum.reduce(parsed, &default_map/2)
  end

  def default_filter(%DoIt.Option{default: nil}), do: false

  def default_filter(%DoIt.Option{}), do: true

  def default_map(%DoIt.Option{name: name, default: default}, parsed) do
    case List.keyfind(parsed, name, 0) do
      nil -> parsed ++ [{name, default}]
      _ -> parsed
    end
  end

  def group(parsed) do
    Enum.reduce(parsed, [], fn {key, value}, acc ->
      case List.keyfind(acc, key, 0) do
        nil -> acc ++ [{key, value}]
        {_, found} when is_list(found) -> List.keyreplace(acc, key, 0, {key, found ++ [value]})
        {_, found} -> List.keyreplace(acc, key, 0, {key, [found] ++ [value]})
      end
    end)
  end

  def validate_input([], _), do: {:ok, []}

  def validate_input(options, parsed) do
    case parsed
         |> Enum.map(fn
           {key, value} ->
             option = Enum.find(options, fn %DoIt.Option{name: name} -> name == key end)

             {option, value}
             |> validate_input_value()
             |> validate_input_allowed_values()
         end)
         |> List.flatten()
         |> Enum.map(fn {%DoIt.Option{name: name}, value} -> {name, value} end)
         |> Enum.split_with(fn
           {_, {:error, _}} -> false
           _ -> true
         end) do
      {valid_options, []} ->
        {:ok, valid_options}

      {_, invalid_options} ->
        {
          :error,
          Enum.map(invalid_options, fn {_, {:error, message}} -> message end)
        }
    end
  end

  def validate_input_value({_, {:error, _}} = error), do: error

  def validate_input_value({%DoIt.Option{} = option, values}) when is_list(values) do
    validate_input_value({option, values}, [])
  end

  def validate_input_value({%DoIt.Option{type: :integer} = option, value}) when is_integer(value),
    do: {option, value}

  def validate_input_value({%DoIt.Option{name: name, type: :integer} = option, value}) do
    {option, String.to_integer(value)}
  rescue
    ArgumentError ->
      {option, {:error, "invalid integer value '#{value}' for option --#{Atom.to_string(name)}"}}
  end

  def validate_input_value({%DoIt.Option{type: :float} = option, value}) when is_float(value),
    do: {option, value}

  def validate_input_value({%DoIt.Option{name: name, type: :float} = option, value}) do
    {option, String.to_float(value)}
  rescue
    ArgumentError ->
      {option, {:error, "invalid float value '#{value}' for option --#{Atom.to_string(name)}"}}
  end

  def validate_input_value({%DoIt.Option{} = option, value}) do
    {option, value}
  end

  def validate_input_value({%DoIt.Option{} = option, [value | values]}, acc) do
    case validate_input_value({option, value}) do
      {%DoIt.Option{}, {:error, _}} = error ->
        error

      {%DoIt.Option{}, val} ->
        validate_input_value({option, values}, acc ++ [val])
    end
  end

  def validate_input_value({%DoIt.Option{} = option, []}, acc) do
    {option, acc}
  end

  def validate_input_allowed_values({_, {:error, _}} = error), do: error

  def validate_input_allowed_values({%DoIt.Option{allowed_values: nil} = option, value}) do
    {option, value}
  end

  def validate_input_allowed_values({%DoIt.Option{} = option, values}) when is_list(values) do
    validate_input_allowed_values({option, values}, [])
  end

  def validate_input_allowed_values(
        {%DoIt.Option{name: name, allowed_values: allowed_values} = option, value}
      ) do
    case Enum.find(allowed_values, fn allowed -> value == allowed end) do
      nil ->
        {option, {:error, "value '#{value}' isn't allowed for option --#{Atom.to_string(name)}"}}

      _ ->
        {option, value}
    end
  end

  def validate_input_allowed_values({%DoIt.Option{} = option, [value | values]}, acc) do
    case validate_input_allowed_values({option, value}) do
      {%DoIt.Option{}, {:error, _}} = error ->
        error

      {%DoIt.Option{}, val} ->
        validate_input_allowed_values({option, values}, acc ++ [val])
    end
  end

  def validate_input_allowed_values({%DoIt.Option{} = option, []}, acc) do
    {option, acc}
  end
end
