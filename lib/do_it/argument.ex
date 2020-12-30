defmodule DoIt.Argument do
  @moduledoc false

  import DoIt.Helper, only: [validate_list_type: 2]

  @argument_types [:boolean, :integer, :float, :string]

  @type t :: %__MODULE__{
          name: atom,
          type: atom,
          description: String.t(),
          allowed_values: list
        }
  @enforce_keys [:name, :type, :description]
  defstruct [:name, :type, :description, :allowed_values]

  def validate_definition(%DoIt.Argument{} = argument) do
    argument
    |> validate_definition_name
    |> validate_definition_type
    |> validate_definition_description
    |> validate_definition_allowed_values
  end

  def validate_definition_name(%DoIt.Argument{name: nil}),
    do: raise(DoIt.ArgumentDefinitionError, message: "name is required for argument definition")

  def validate_definition_name(%DoIt.Argument{name: name} = argument) when is_atom(name), do: argument

  def validate_definition_name(%DoIt.Argument{name: _}),
    do: raise(DoIt.ArgumentDefinitionError, message: "name must be an atom")

  def validate_definition_type(%DoIt.Argument{type: nil}),
    do: raise(DoIt.ArgumentDefinitionError, message: "type is required for argument definition")

  def validate_definition_type(%DoIt.Argument{type: type} = argument) when type in @argument_types,
    do: argument

  def validate_definition_type(%DoIt.Argument{type: type}),
    do:
      raise(DoIt.ArgumentDefinitionError,
        message: "unrecognized argument type '#{type}', allowed types are #{inspect(@argument_types)}"
      )

  def validate_definition_description(%DoIt.Argument{description: nil}),
    do: raise(DoIt.ArgumentDefinitionError, message: "description is required for argument definition")

  def validate_definition_description(%DoIt.Argument{description: description} = argument)
      when is_binary(description),
      do: argument

  def validate_definition_description(%DoIt.Argument{description: _}),
    do: raise(DoIt.ArgumentDefinitionError, message: "description must be a string")

  def validate_definition_allowed_values(%DoIt.Argument{allowed_values: nil} = argument), do: argument

  def validate_definition_allowed_values(%DoIt.Argument{type: type, allowed_values: _})
      when type == :boolean,
      do:
        raise(DoIt.ArgumentDefinitionError,
          message: "allowed_values cannot be used with type :boolean"
        )

  def validate_definition_allowed_values(
        %DoIt.Argument{type: type, allowed_values: allowed_values} = argument
      )
      when is_list(allowed_values) do
    case validate_list_type(allowed_values, type) do
      true ->
        argument

      _ ->
        raise DoIt.ArgumentDefinitionError,
          message: "all values in allowed_values must be of type #{inspect(type)}"
    end
  end

  def validate_definition_allowed_values(%DoIt.Argument{allowed_values: _}),
    do: raise(DoIt.ArgumentDefinitionError, message: "allowed_values must be a list")

  def parse_input(arguments, parsed) do
    cond do
      Enum.count(arguments) != Enum.count(parsed) ->
        {:error, "wrong number of arguments"}

      Enum.empty?(arguments) == 0 ->
        {:ok, []}

      true ->
        argument_keys =
          arguments
          |> Enum.map(fn %{name: name} -> name end)
          |> Enum.reverse()

        {
          :ok,
          Enum.zip(argument_keys, parsed)
        }
    end
  end

  def validate_input([], _), do: {:ok, []}

  def validate_input(arguments, parsed) do
    case parsed
         |> Enum.map(fn
           {key, value} ->
             argument = Enum.find(arguments, fn %DoIt.Argument{name: name} -> name == key end)

             {argument, value}
             |> validate_input_value()
             |> validate_input_allowed_values()
         end)
         |> List.flatten()
         |> Enum.map(fn {%DoIt.Argument{name: name}, value} -> {name, value} end)
         |> Enum.split_with(fn
           {_, {:error, _}} -> false
           _ -> true
         end) do
      {valid_arguments, []} ->
        {:ok, valid_arguments}

      {_, invalid_arguments} ->
        {
          :error,
          Enum.map(invalid_arguments, fn {_, {:error, message}} -> message end)
        }
    end
  end

  def validate_input_value({_, {:error, _}} = error), do: error

  def validate_input_value({%DoIt.Argument{} = argument, values}) when is_list(values) do
    validate_input_value({argument, values}, [])
  end

  def validate_input_value({%DoIt.Argument{type: :integer} = argument, value}) when is_integer(value),
    do: {argument, value}

  def validate_input_value({%DoIt.Argument{name: name, type: :integer} = argument, value}) do
    {argument, String.to_integer(value)}
  rescue
    ArgumentError ->
      {argument, {:error, "invalid :integer value '#{value}' for argument #{inspect(name)}"}}
  end

  def validate_input_value({%DoIt.Argument{type: :float} = argument, value}) when is_float(value),
    do: {argument, value}

  def validate_input_value({%DoIt.Argument{name: name, type: :float} = argument, value}) do
    {argument, String.to_float(value)}
  rescue
    ArgumentError ->
      {argument, {:error, "invalid :float value '#{value}' for argument #{inspect(name)}"}}
  end

  def validate_input_value({%DoIt.Argument{} = argument, value}) do
    {argument, "#{value}"}
  end

  def validate_input_value({%DoIt.Argument{} = argument, [value | values]}, acc) do
    case validate_input_value({argument, value}) do
      {%DoIt.Argument{}, {:error, _}} = error ->
        error

      {%DoIt.Argument{}, val} ->
        validate_input_value({argument, values}, acc ++ [val])
    end
  end

  def validate_input_value({%DoIt.Argument{} = argument, []}, acc) do
    {argument, acc}
  end

  def validate_input_allowed_values({_, {:error, _}} = error), do: error

  def validate_input_allowed_values({%DoIt.Argument{allowed_values: nil} = argument, value}) do
    {argument, value}
  end

  def validate_input_allowed_values({%DoIt.Argument{} = argument, values}) when is_list(values) do
    validate_input_allowed_values({argument, values}, [])
  end

  def validate_input_allowed_values(
        {%DoIt.Argument{name: name, allowed_values: allowed_values} = argument, value}
      ) do
    case Enum.find(allowed_values, fn allowed -> value == allowed end) do
      nil -> {argument, {:error, "value '#{value}' isn't allowed for argument #{inspect(name)}"}}
      _ -> {argument, value}
    end
  end

  def validate_input_allowed_values({%DoIt.Argument{} = argument, [value | values]}, acc) do
    case validate_input_allowed_values({argument, value}) do
      {%DoIt.Argument{}, {:error, _}} = error ->
        error

      {%DoIt.Argument{}, val} ->
        validate_input_allowed_values({argument, values}, acc ++ [val])
    end
  end

  def validate_input_allowed_values({%DoIt.Argument{} = argument, []}, acc) do
    {argument, acc}
  end
end
