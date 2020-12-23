defmodule DoIt.Flag do
  @moduledoc false

  import DoIt.Helper, only: [validate_list_type: 2]

  @flag_types [:boolean, :count, :integer, :float, :string]

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

  def validate_definition(%DoIt.Flag{} = flag) do
    flag
    |> validate_definition_name
    |> validate_definition_type
    |> validate_definition_description
    |> validate_definition_alias
    |> validate_definition_keep
    |> validate_definition_allowed_values
    |> validate_definition_default
  end

  def validate_definition_name(%DoIt.Flag{name: nil}),
    do: raise(DoIt.FlagDefinitionError, message: "name is required for flag definition")

  def validate_definition_name(%DoIt.Flag{name: name} = flag) when is_atom(name), do: flag

  def validate_definition_name(%DoIt.Flag{name: _}),
    do: raise(DoIt.FlagDefinitionError, message: "name must be an atom")

  def validate_definition_type(%DoIt.Flag{type: nil}),
    do: raise(DoIt.FlagDefinitionError, message: "type is required for flag definition")

  def validate_definition_type(%DoIt.Flag{type: type} = flag) when type in @flag_types, do: flag

  def validate_definition_type(%DoIt.Flag{type: type}),
    do:
      raise(DoIt.FlagDefinitionError,
        message: "unrecognized flag type '#{type}', allowed types are #{inspect(@flag_types)}"
      )

  def validate_definition_description(%DoIt.Flag{description: nil}),
    do: raise(DoIt.FlagDefinitionError, message: "description is required for flag definition")

  def validate_definition_description(%DoIt.Flag{description: description} = flag)
      when is_binary(description),
      do: flag

  def validate_definition_description(%DoIt.Flag{description: _}),
    do: raise(DoIt.FlagDefinitionError, message: "description must be a string")

  def validate_definition_alias(%DoIt.Flag{alias: nil} = flag), do: flag
  def validate_definition_alias(%DoIt.Flag{alias: alias} = flag) when is_atom(alias), do: flag

  def validate_definition_alias(%DoIt.Flag{alias: _}),
    do: raise(DoIt.FlagDefinitionError, message: "alias must be an atom")

  def validate_definition_keep(%DoIt.Flag{keep: nil} = flag), do: flag

  def validate_definition_keep(%DoIt.Flag{type: :count, keep: _}),
    do: raise(DoIt.FlagDefinitionError, message: "keep cannot be used with type :count")

  def validate_definition_keep(%DoIt.Flag{keep: keep} = flag) when is_boolean(keep), do: flag

  def validate_definition_keep(%DoIt.Flag{keep: _}),
    do: raise(DoIt.FlagDefinitionError, message: "keep must be a boolean")

  def validate_definition_allowed_values(%DoIt.Flag{allowed_values: nil} = flag), do: flag

  def validate_definition_allowed_values(%DoIt.Flag{type: type, allowed_values: _})
      when type in [:boolean, :count],
      do:
        raise(DoIt.FlagDefinitionError,
          message: "allowed_values cannot be used with types :boolean and :count"
        )

  def validate_definition_allowed_values(
        %DoIt.Flag{type: type, allowed_values: allowed_values} = flag
      )
      when is_list(allowed_values) do
    case validate_list_type(allowed_values, type) do
      true ->
        flag

      _ ->
        raise DoIt.FlagDefinitionError,
          message: "all values in allowed_values must be of type #{inspect(type)}"
    end
  end

  def validate_definition_allowed_values(%DoIt.Flag{allowed_values: _}),
    do: raise(DoIt.FlagDefinitionError, message: "allowed_values must be a list")

  def validate_definition_default(%DoIt.Flag{default: nil} = flag), do: flag

  def validate_definition_default(
        %DoIt.Flag{type: :string, default: default, allowed_values: nil} = flag
      )
      when is_binary(default),
      do: flag

  def validate_definition_default(
        %DoIt.Flag{type: :integer, default: default, allowed_values: nil} = flag
      )
      when is_integer(default),
      do: flag

  def validate_definition_default(
        %DoIt.Flag{type: :float, default: default, allowed_values: nil} = flag
      )
      when is_float(default),
      do: flag

  def validate_definition_default(
        %DoIt.Flag{type: :boolean, default: default, allowed_values: nil} = flag
      )
      when is_boolean(default),
      do: flag

  def validate_definition_default(
        %DoIt.Flag{type: :count, default: default, allowed_values: nil} = flag
      )
      when is_integer(default),
      do: flag

  def validate_definition_default(%DoIt.Flag{type: type, default: _, allowed_values: nil}),
    do: raise(DoIt.FlagDefinitionError, message: "default value must be of type #{inspect(type)}")

  def validate_definition_default(
        %DoIt.Flag{default: default, allowed_values: allowed_values} = flag
      ) do
    case default in allowed_values do
      true ->
        flag

      _ ->
        raise DoIt.FlagDefinitionError,
          message: "default value must be included in allowed_values"
    end
  end

  def parse_input(flags, parsed) do
    {
      :ok,
      flags
      |> default(parsed)
      |> group()
    }
  end

  def default(flags, parsed) do
    flags
    |> Enum.filter(&default_filter/1)
    |> Enum.reduce(parsed, &default_map/2)
  end

  def default_filter(%DoIt.Flag{default: nil}), do: false

  def default_filter(%DoIt.Flag{}), do: true

  def default_map(%DoIt.Flag{name: name, default: default}, parsed) do
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

  def validate_input(flags, parsed) do
    case parsed
         |> Enum.map(fn
           {key, value} ->
             flag = Enum.find(flags, fn %DoIt.Flag{name: name} -> name == key end)

             {flag, value}
             |> validate_input_value()
             |> validate_input_allowed_values()
         end)
         |> List.flatten()
         |> Enum.map(fn {%DoIt.Flag{name: name}, value} -> {name, value} end)
         |> Enum.split_with(fn
           {_, {:error, _}} -> false
           _ -> true
         end) do
      {valid_flags, []} ->
        {:ok, valid_flags}

      {_, invalid_flags} ->
        {
          :error,
          Enum.map(invalid_flags, fn {_, {:error, message}} -> message end)
        }
    end
  end

  def validate_input_value({_, {:error, _}} = error), do: error

  def validate_input_value({%DoIt.Flag{} = flag, values}) when is_list(values) do
    validate_input_value({flag, values}, [])
  end

  def validate_input_value({%DoIt.Flag{type: :integer} = flag, value}) when is_integer(value),
    do: {flag, value}

  def validate_input_value({%DoIt.Flag{name: name, type: :integer} = flag, value}) do
    {flag, String.to_integer(value)}
  rescue
    ArgumentError ->
      {flag, {:error, "invalid :integer value '#{value}' for flag #{inspect(name)}"}}
  end

  def validate_input_value({%DoIt.Flag{type: :float} = flag, value}) when is_float(value),
    do: {flag, value}

  def validate_input_value({%DoIt.Flag{name: name, type: :float} = flag, value}) do
    {flag, String.to_float(value)}
  rescue
    ArgumentError -> {flag, {:error, "invalid :float value '#{value}' for flag #{inspect(name)}"}}
  end

  def validate_input_value({%DoIt.Flag{} = flag, value}) do
    {flag, "#{value}"}
  end

  def validate_input_value({%DoIt.Flag{} = flag, [value | values]}, acc) do
    case validate_input_value({flag, value}) do
      {%DoIt.Flag{}, {:error, _}} = error ->
        error

      {%DoIt.Flag{}, val} ->
        validate_input_value({flag, values}, acc ++ [val])
    end
  end

  def validate_input_value({%DoIt.Flag{} = flag, []}, acc) do
    {flag, acc}
  end

  def validate_input_allowed_values({_, {:error, _}} = error), do: error

  def validate_input_allowed_values({%DoIt.Flag{allowed_values: nil} = flag, value}) do
    {flag, value}
  end

  def validate_input_allowed_values({%DoIt.Flag{} = flag, values}) when is_list(values) do
    validate_input_allowed_values({flag, values}, [])
  end

  def validate_input_allowed_values(
        {%DoIt.Flag{name: name, allowed_values: allowed_values} = flag, value}
      ) do
    case Enum.find(allowed_values, fn allowed -> value == allowed end) do
      nil -> {flag, {:error, "value '#{value}' isn't allowed for flag #{inspect(name)}"}}
      _ -> {flag, value}
    end
  end

  def validate_input_allowed_values({%DoIt.Flag{} = flag, [value | values]}, acc) do
    case validate_input_allowed_values({flag, value}) do
      {%DoIt.Flag{}, {:error, _}} = error ->
        error

      {%DoIt.Flag{}, val} ->
        validate_input_allowed_values({flag, values}, acc ++ [val])
    end
  end

  def validate_input_allowed_values({%DoIt.Flag{} = flag, []}, acc) do
    {flag, acc}
  end
end
