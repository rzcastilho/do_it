defmodule DoIt.Param do
  @moduledoc false

  import DoIt.Helper, only: [validate_list_type: 2]

  @param_types [:boolean, :integer, :float, :string]

  @type t :: %__MODULE__{
          name: atom,
          type: atom,
          description: String.t(),
          allowed_values: list
        }
  @enforce_keys [:name, :type, :description]
  defstruct [:name, :type, :description, :allowed_values]

  def validate_definition(%DoIt.Param{} = param) do
    param
    |> validate_definition_name
    |> validate_definition_type
    |> validate_definition_description
    |> validate_definition_allowed_values
  end

  def validate_definition_name(%DoIt.Param{name: nil}),
    do: raise(DoIt.ParamDefinitionError, message: "name is required for param definition")

  def validate_definition_name(%DoIt.Param{name: name} = param) when is_atom(name), do: param

  def validate_definition_name(%DoIt.Param{name: _}),
    do: raise(DoIt.ParamDefinitionError, message: "name must be an atom")

  def validate_definition_type(%DoIt.Param{type: nil}),
    do: raise(DoIt.ParamDefinitionError, message: "type is required for param definition")

  def validate_definition_type(%DoIt.Param{type: type} = param) when type in @param_types,
    do: param

  def validate_definition_type(%DoIt.Param{type: type}),
    do:
      raise(DoIt.ParamDefinitionError,
        message: "unrecognized param type '#{type}', allowed types are #{inspect(@param_types)}"
      )

  def validate_definition_description(%DoIt.Param{description: nil}),
    do: raise(DoIt.ParamDefinitionError, message: "description is required for param definition")

  def validate_definition_description(%DoIt.Param{description: description} = param)
      when is_binary(description),
      do: param

  def validate_definition_description(%DoIt.Param{description: _}),
    do: raise(DoIt.ParamDefinitionError, message: "description must be a string")

  def validate_definition_allowed_values(%DoIt.Param{allowed_values: nil} = param), do: param

  def validate_definition_allowed_values(%DoIt.Param{type: type, allowed_values: _})
      when type == :boolean,
      do:
        raise(DoIt.ParamDefinitionError,
          message: "allowed_values cannot be used with type :boolean"
        )

  def validate_definition_allowed_values(
        %DoIt.Param{type: type, allowed_values: allowed_values} = param
      )
      when is_list(allowed_values) do
    case validate_list_type(allowed_values, type) do
      true ->
        param

      _ ->
        raise DoIt.ParamDefinitionError,
          message: "all values in allowed_values must be of type #{inspect(type)}"
    end
  end

  def validate_definition_allowed_values(%DoIt.Param{allowed_values: _}),
    do: raise(DoIt.ParamDefinitionError, message: "allowed_values must be a list")

  def parse_input(params, parsed) do
    cond do
      Enum.count(params) != Enum.count(parsed) ->
        {:error, "wrong number of params"}

      Enum.empty?(params) == 0 ->
        {:ok, []}

      true ->
        param_keys =
          params
          |> Enum.map(fn %{name: name} -> name end)
          |> Enum.reverse()

        {
          :ok,
          Enum.zip(param_keys, parsed)
        }
    end
  end

  def validate_input([], _), do: {:ok, []}

  def validate_input(params, parsed) do
    case parsed
         |> Enum.map(fn
           {key, value} ->
             param = Enum.find(params, fn %DoIt.Param{name: name} -> name == key end)

             {param, value}
             |> validate_input_value()
             |> validate_input_allowed_values()
         end)
         |> List.flatten()
         |> Enum.map(fn {%DoIt.Param{name: name}, value} -> {name, value} end)
         |> Enum.split_with(fn
           {_, {:error, _}} -> false
           _ -> true
         end) do
      {valid_params, []} ->
        {:ok, valid_params}

      {_, invalid_params} ->
        {
          :error,
          Enum.map(invalid_params, fn {_, {:error, message}} -> message end)
        }
    end
  end

  def validate_input_value({_, {:error, _}} = error), do: error

  def validate_input_value({%DoIt.Param{} = param, values}) when is_list(values) do
    validate_input_value({param, values}, [])
  end

  def validate_input_value({%DoIt.Param{type: :integer} = param, value}) when is_integer(value),
    do: {param, value}

  def validate_input_value({%DoIt.Param{name: name, type: :integer} = param, value}) do
    {param, String.to_integer(value)}
  rescue
    ArgumentError ->
      {param, {:error, "invalid :integer value '#{value}' for param #{inspect(name)}"}}
  end

  def validate_input_value({%DoIt.Param{type: :float} = param, value}) when is_float(value),
    do: {param, value}

  def validate_input_value({%DoIt.Param{name: name, type: :float} = param, value}) do
    {param, String.to_float(value)}
  rescue
    ArgumentError ->
      {param, {:error, "invalid :float value '#{value}' for param #{inspect(name)}"}}
  end

  def validate_input_value({%DoIt.Param{} = param, value}) do
    {param, "#{value}"}
  end

  def validate_input_value({%DoIt.Param{} = param, [value | values]}, acc) do
    case validate_input_value({param, value}) do
      {%DoIt.Param{}, {:error, _}} = error ->
        error

      {%DoIt.Param{}, val} ->
        validate_input_value({param, values}, acc ++ [val])
    end
  end

  def validate_input_value({%DoIt.Param{} = param, []}, acc) do
    {param, acc}
  end

  def validate_input_allowed_values({_, {:error, _}} = error), do: error

  def validate_input_allowed_values({%DoIt.Param{allowed_values: nil} = param, value}) do
    {param, value}
  end

  def validate_input_allowed_values({%DoIt.Param{} = param, values}) when is_list(values) do
    validate_input_allowed_values({param, values}, [])
  end

  def validate_input_allowed_values(
        {%DoIt.Param{name: name, allowed_values: allowed_values} = param, value}
      ) do
    case Enum.find(allowed_values, fn allowed -> value == allowed end) do
      nil -> {param, {:error, "value '#{value}' isn't allowed for param #{inspect(name)}"}}
      _ -> {param, value}
    end
  end

  def validate_input_allowed_values({%DoIt.Param{} = param, [value | values]}, acc) do
    case validate_input_allowed_values({param, value}) do
      {%DoIt.Param{}, {:error, _}} = error ->
        error

      {%DoIt.Param{}, val} ->
        validate_input_allowed_values({param, values}, acc ++ [val])
    end
  end

  def validate_input_allowed_values({%DoIt.Param{} = param, []}, acc) do
    {param, acc}
  end
end
