defmodule DoIt.ParamTest do
  @moduledoc false
  use ExUnit.Case
  doctest DoIt.Param

  alias DoIt.Param
  alias DoIt.ParamDefinitionError

  setup_all do
    {
      :ok,
      param: %Param{
        name: :test,
        type: :string,
        description: "Param test description",
        allowed_values: ["test", "assert", "refute"]
      },
      params: [
        %DoIt.Param{
          allowed_values: ["repos", "following", "followers"],
          description: "GitHub user's thing",
          name: :thing,
          type: :string
        },
        %DoIt.Param{
          allowed_values: nil,
          description: "GitHub username",
          name: :username,
          type: :string
        }
      ],
      parsed: ["rzcastilho", "repos"]
    }
  end

  test "valid param definition", %{param: param} do
    assert %{name: _, type: _, description: _, allowed_values: _} =
             Param.validate_definition(param)
  end

  test "valid param definition without allowed_values", %{param: param} do
    assert %{name: _, type: _, description: _, allowed_values: nil} =
             param
             |> Map.put(:allowed_values, nil)
             |> Param.validate_definition()
  end

  test "name is required for param definition", %{param: param} do
    assert_raise ParamDefinitionError, "name is required for param definition", fn ->
      param
      |> Map.put(:name, nil)
      |> Param.validate_definition()
    end
  end

  test "name must be an atom", %{param: param} do
    assert_raise ParamDefinitionError, "name must be an atom", fn ->
      param
      |> Map.put(:name, "test")
      |> Param.validate_definition()
    end
  end

  test "type is required for param definition", %{param: param} do
    assert_raise ParamDefinitionError, "type is required for param definition", fn ->
      param
      |> Map.put(:type, nil)
      |> Param.validate_definition()
    end
  end

  test "unrecognized param type", %{param: param} do
    assert_raise ParamDefinitionError, ~r/^unrecognized param type/, fn ->
      param
      |> Map.put(:type, :unknown)
      |> Param.validate_definition()
    end
  end

  test "description is required for param definition", %{param: param} do
    assert_raise ParamDefinitionError, "description is required for param definition", fn ->
      param
      |> Map.put(:description, nil)
      |> Param.validate_definition()
    end
  end

  test "description must be a string", %{param: param} do
    assert_raise ParamDefinitionError, "description must be a string", fn ->
      param
      |> Map.put(:description, 123)
      |> Param.validate_definition()
    end
  end

  test "allowed_values cannot be used with type :boolean", %{param: param} do
    assert_raise ParamDefinitionError, "allowed_values cannot be used with type :boolean", fn ->
      param
      |> Map.put(:type, :boolean)
      |> Param.validate_definition()
    end
  end

  test "all values in allowed_values must be of the same type of param", %{param: param} do
    assert_raise ParamDefinitionError, ~r/^all values in allowed_values must be of type/, fn ->
      param
      |> Map.put(:allowed_values, ["test", :assert, true])
      |> Param.validate_definition()
    end
  end

  test "allowed_values must be a list", %{param: param} do
    assert_raise ParamDefinitionError, "allowed_values must be a list", fn ->
      param
      |> Map.put(:allowed_values, "test")
      |> Param.validate_definition()
    end
  end

  test "parse input params", %{params: params, parsed: parsed} do
    assert {:ok, _} = Param.parse_input(params, parsed)
  end

  test "parse no input params" do
    assert {:ok, []} = Param.parse_input([], [])
  end

  test "parse input wrong number of params", %{params: params} do
    assert {:error, "wrong number of params"} = Param.parse_input(params, ["rzcastilho"])
  end

  test "valid input value param - integer" do
    param = %Param{name: :test, type: :integer, description: "Test"}
    assert {%Param{}, 10} = Param.validate_input_value({param, "10"})
  end

  test "invalid input value param - integer" do
    param = %Param{name: :test, type: :integer, description: "Test"}
    assert {%Param{}, {:error, _}} = Param.validate_input_value({param, "10i"})
  end

  test "valid input value param - float" do
    param = %Param{name: :test, type: :float, description: "Test"}
    assert {%Param{}, 11.1} = Param.validate_input_value({param, "11.1"})
  end

  test "invalid input value param - float" do
    param = %Param{name: :test, type: :float, description: "Test"}
    assert {%Param{}, {:error, _}} = Param.validate_input_value({param, "11.1i"})
  end

  test "invalid input value param list" do
    param = %Param{name: :test, type: :float, description: "Test"}

    assert {%Param{}, {:error, _}} =
             Param.validate_input_value({param, ["33.3", "22.2i", "11.1"]})
  end

  test "valid input params", %{params: params, parsed: parsed} do
    {:ok, parsed_params} = Param.parse_input(params, parsed)
    assert {:ok, _} = Param.validate_input(params, parsed_params)
  end

  test "propagate error for valid input value params", %{param: param} do
    assert {%Param{}, {:error, _}} =
             Param.validate_input_value({param, {:error, "invalid param"}})
  end

  test "valid input allowed_values param", %{param: param} do
    assert {%Param{}, _} = Param.validate_input_allowed_values({param, "test"})
  end

  test "invalid input allowed_values param", %{param: param} do
    assert {%Param{}, {:error, _}} = Param.validate_input_allowed_values({param, "test123"})
  end

  test "valid input allowed_values param - list", %{param: param} do
    assert {%Param{}, _} = Param.validate_input_allowed_values({param, ["test", "assert"]})
  end

  test "invalid input allowed_values param - list", %{param: param} do
    assert {%Param{}, {:error, _}} =
             Param.validate_input_allowed_values({param, ["test", "assert", "none"]})
  end

  test "propagate error for valid input allowed_values params", %{param: param} do
    assert {%Param{}, {:error, _}} =
             Param.validate_input_allowed_values({param, {:error, "invalid param"}})
  end

  test "invalid input params", %{params: params, parsed: parsed} do
    {:ok, parsed_params} = Param.parse_input(params, parsed)

    assert {:error, _} =
             Param.validate_input(
               params,
               List.keyreplace(parsed_params, :thing, 0, {:thing, "reposs"})
             )
  end
end
