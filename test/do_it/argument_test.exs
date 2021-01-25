defmodule DoIt.ArgumentTest do
  @moduledoc false
  use ExUnit.Case
  doctest DoIt.Argument

  alias DoIt.Argument
  alias DoIt.ArgumentDefinitionError

  setup_all do
    {
      :ok,
      argument: %Argument{
        name: :test,
        type: :string,
        description: "Argument test description",
        allowed_values: ["test", "assert", "refute"]
      },
      arguments: [
        %DoIt.Argument{
          allowed_values: ["repos", "following", "followers"],
          description: "GitHub user's thing",
          name: :thing,
          type: :string
        },
        %DoIt.Argument{
          allowed_values: nil,
          description: "GitHub username",
          name: :username,
          type: :string
        }
      ],
      parsed: ["rzcastilho", "repos"]
    }
  end

  test "valid argument definition", %{argument: argument} do
    assert %{name: _, type: _, description: _, allowed_values: _} =
             Argument.validate_definition(argument)
  end

  test "valid argument definition without allowed_values", %{argument: argument} do
    assert %{name: _, type: _, description: _, allowed_values: nil} =
             argument
             |> Map.put(:allowed_values, nil)
             |> Argument.validate_definition()
  end

  test "name is required for argument definition", %{argument: argument} do
    assert_raise ArgumentDefinitionError, "name is required for argument definition", fn ->
      argument
      |> Map.put(:name, nil)
      |> Argument.validate_definition()
    end
  end

  test "name must be an atom", %{argument: argument} do
    assert_raise ArgumentDefinitionError, "name must be an atom", fn ->
      argument
      |> Map.put(:name, "test")
      |> Argument.validate_definition()
    end
  end

  test "type is required for argument definition", %{argument: argument} do
    assert_raise ArgumentDefinitionError, "type is required for argument definition", fn ->
      argument
      |> Map.put(:type, nil)
      |> Argument.validate_definition()
    end
  end

  test "unrecognized argument type", %{argument: argument} do
    assert_raise ArgumentDefinitionError, ~r/^unrecognized argument type/, fn ->
      argument
      |> Map.put(:type, :unknown)
      |> Argument.validate_definition()
    end
  end

  test "description is required for argument definition", %{argument: argument} do
    assert_raise ArgumentDefinitionError, "description is required for argument definition", fn ->
      argument
      |> Map.put(:description, nil)
      |> Argument.validate_definition()
    end
  end

  test "description must be a string", %{argument: argument} do
    assert_raise ArgumentDefinitionError, "description must be a string", fn ->
      argument
      |> Map.put(:description, 123)
      |> Argument.validate_definition()
    end
  end

  test "allowed_values cannot be used with type boolean", %{argument: argument} do
    assert_raise ArgumentDefinitionError,
                 "allowed_values cannot be used with type boolean",
                 fn ->
                   argument
                   |> Map.put(:type, :boolean)
                   |> Argument.validate_definition()
                 end
  end

  test "all values in allowed_values must be of the same type of argument", %{argument: argument} do
    assert_raise ArgumentDefinitionError, ~r/^all values in allowed_values must be of type/, fn ->
      argument
      |> Map.put(:allowed_values, ["test", :assert, true])
      |> Argument.validate_definition()
    end
  end

  test "allowed_values must be a list", %{argument: argument} do
    assert_raise ArgumentDefinitionError, "allowed_values must be a list", fn ->
      argument
      |> Map.put(:allowed_values, "test")
      |> Argument.validate_definition()
    end
  end

  test "parse input arguments", %{arguments: arguments, parsed: parsed} do
    assert {:ok, _} = Argument.parse_input(arguments, parsed)
  end

  test "parse no input arguments" do
    assert {:ok, []} = Argument.parse_input([], [])
  end

  test "parse input wrong number of arguments", %{arguments: arguments} do
    assert {:error, "wrong number of arguments (given 1 expected 2)"} =
             Argument.parse_input(arguments, ["rzcastilho"])
  end

  test "valid input value argument - integer" do
    argument = %Argument{name: :test, type: :integer, description: "Test"}
    assert {%Argument{}, 10} = Argument.validate_input_value({argument, "10"})
  end

  test "invalid input value argument - integer" do
    argument = %Argument{name: :test, type: :integer, description: "Test"}
    assert {%Argument{}, {:error, _}} = Argument.validate_input_value({argument, "10i"})
  end

  test "valid input value argument - float" do
    argument = %Argument{name: :test, type: :float, description: "Test"}
    assert {%Argument{}, 11.1} = Argument.validate_input_value({argument, "11.1"})
  end

  test "invalid input value argument - float" do
    argument = %Argument{name: :test, type: :float, description: "Test"}
    assert {%Argument{}, {:error, _}} = Argument.validate_input_value({argument, "11.1i"})
  end

  test "invalid input value argument list" do
    argument = %Argument{name: :test, type: :float, description: "Test"}

    assert {%Argument{}, {:error, _}} =
             Argument.validate_input_value({argument, ["33.3", "22.2i", "11.1"]})
  end

  test "valid input arguments", %{arguments: arguments, parsed: parsed} do
    {:ok, parsed_arguments} = Argument.parse_input(arguments, parsed)
    assert {:ok, _} = Argument.validate_input(arguments, parsed_arguments)
  end

  test "propagate error for valid input value arguments", %{argument: argument} do
    assert {%Argument{}, {:error, _}} =
             Argument.validate_input_value({argument, {:error, "invalid argument"}})
  end

  test "valid input allowed_values argument", %{argument: argument} do
    assert {%Argument{}, _} = Argument.validate_input_allowed_values({argument, "test"})
  end

  test "invalid input allowed_values argument", %{argument: argument} do
    assert {%Argument{}, {:error, _}} =
             Argument.validate_input_allowed_values({argument, "test123"})
  end

  test "valid input allowed_values argument - list", %{argument: argument} do
    assert {%Argument{}, _} =
             Argument.validate_input_allowed_values({argument, ["test", "assert"]})
  end

  test "invalid input allowed_values argument - list", %{argument: argument} do
    assert {%Argument{}, {:error, _}} =
             Argument.validate_input_allowed_values({argument, ["test", "assert", "none"]})
  end

  test "propagate error for valid input allowed_values arguments", %{argument: argument} do
    assert {%Argument{}, {:error, _}} =
             Argument.validate_input_allowed_values({argument, {:error, "invalid argument"}})
  end

  test "invalid input arguments", %{arguments: arguments, parsed: parsed} do
    {:ok, parsed_arguments} = Argument.parse_input(arguments, parsed)

    assert {:error, _} =
             Argument.validate_input(
               arguments,
               List.keyreplace(parsed_arguments, :thing, 0, {:thing, "reposs"})
             )
  end
end
