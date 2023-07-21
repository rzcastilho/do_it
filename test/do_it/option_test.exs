defmodule DoIt.OptionTest do
  @moduledoc false
  use ExUnit.Case
  doctest DoIt.Option

  alias DoIt.Option
  alias DoIt.OptionDefinitionError

  setup_all do
    {
      :ok,
      option: %Option{
        name: :test,
        type: :string,
        description: "Option test description",
        alias: :t,
        default: "test",
        keep: false,
        allowed_values: ["test", "assert", "refute"]
      },
      options: [
        %DoIt.Option{
          alias: nil,
          allowed_values: nil,
          default: 5,
          description: "Max number of search results",
          keep: nil,
          name: :limit,
          type: :integer
        },
        %DoIt.Option{
          alias: nil,
          allowed_values: ["table", "csv", "json"],
          default: "table",
          description: "Output format",
          keep: nil,
          name: :format,
          type: :string
        },
        %DoIt.Option{
          alias: :f,
          allowed_values: nil,
          default: nil,
          description: "Filter output based on conditions provided",
          keep: true,
          name: :filter,
          type: :string
        }
      ],
      parsed: [filter: "elixir", filter: "metaprogramming", filter: "do_it"]
    }
  end

  test "valid option definition", %{option: option} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: _, allowed_values: _} =
             Option.validate_definition(option)
  end

  test "valid option definition of type integer", %{option: option} do
    assert %{
             name: _,
             type: _,
             description: _,
             alias: _,
             default: _,
             keep: nil,
             allowed_values: nil
           } =
             option
             |> Map.put(:type, :integer)
             |> Map.put(:default, 1)
             |> Map.put(:allowed_values, nil)
             |> Map.put(:keep, nil)
             |> Option.validate_definition()
  end

  test "valid option definition of type integer with allowed_values", %{option: option} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: nil, allowed_values: _} =
             option
             |> Map.put(:type, :integer)
             |> Map.put(:default, 1)
             |> Map.put(:allowed_values, [1, 2, 3, 4])
             |> Map.put(:keep, nil)
             |> Option.validate_definition()
  end

  test "valid option definition of type float", %{option: option} do
    assert %{
             name: _,
             type: _,
             description: _,
             alias: _,
             default: _,
             keep: nil,
             allowed_values: nil
           } =
             option
             |> Map.put(:type, :float)
             |> Map.put(:default, 1.5)
             |> Map.put(:allowed_values, nil)
             |> Map.put(:keep, nil)
             |> Option.validate_definition()
  end

  test "valid option definition of type float with allowed_values", %{option: option} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: nil, allowed_values: _} =
             option
             |> Map.put(:type, :float)
             |> Map.put(:default, 1.5)
             |> Map.put(:allowed_values, [1.0, 1.25, 1.5, 1.75, 2.0])
             |> Map.put(:keep, nil)
             |> Option.validate_definition()
  end

  test "valid option definition of type boolean", %{option: option} do
    assert %{
             name: _,
             type: _,
             description: _,
             alias: _,
             default: _,
             keep: nil,
             allowed_values: nil
           } =
             option
             |> Map.put(:type, :boolean)
             |> Map.put(:default, true)
             |> Map.put(:keep, nil)
             |> Map.put(:allowed_values, nil)
             |> Option.validate_definition()
  end

  test "valid option definition of type count", %{option: option} do
    assert %{
             name: _,
             type: _,
             description: _,
             alias: _,
             default: _,
             keep: nil,
             allowed_values: nil
           } =
             option
             |> Map.put(:type, :count)
             |> Map.put(:default, 10)
             |> Map.put(:keep, nil)
             |> Map.put(:allowed_values, nil)
             |> Option.validate_definition()
  end

  test "valid option definition without alias", %{option: option} do
    assert %{name: _, type: _, description: _, alias: nil, default: _, keep: _, allowed_values: _} =
             option
             |> Map.put(:alias, nil)
             |> Option.validate_definition()
  end

  test "valid option definition without allowed_values", %{option: option} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: _, allowed_values: nil} =
             option
             |> Map.put(:allowed_values, nil)
             |> Option.validate_definition()
  end

  test "valid option definition without default", %{option: option} do
    assert %{name: _, type: _, description: _, alias: _, default: nil, keep: _, allowed_values: _} =
             option
             |> Map.put(:default, nil)
             |> Option.validate_definition()
  end

  test "valid option definition without keep", %{option: option} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: nil, allowed_values: _} =
             option
             |> Map.put(:keep, nil)
             |> Option.validate_definition()
  end

  test "name is required for option definition", %{option: option} do
    assert_raise OptionDefinitionError, "name is required for option definition", fn ->
      option
      |> Map.put(:name, nil)
      |> Option.validate_definition()
    end
  end

  test "name must be an atom", %{option: option} do
    assert_raise OptionDefinitionError, "name must be an atom", fn ->
      option
      |> Map.put(:name, "test")
      |> Option.validate_definition()
    end
  end

  test "type is required for option definition", %{option: option} do
    assert_raise OptionDefinitionError, "type is required for option definition", fn ->
      option
      |> Map.put(:type, nil)
      |> Option.validate_definition()
    end
  end

  test "unrecognized option type", %{option: option} do
    assert_raise OptionDefinitionError, ~r/^unrecognized option type/, fn ->
      option
      |> Map.put(:type, :unknown)
      |> Option.validate_definition()
    end
  end

  test "description is required for option definition", %{option: option} do
    assert_raise OptionDefinitionError, "description is required for option definition", fn ->
      option
      |> Map.put(:description, nil)
      |> Option.validate_definition()
    end
  end

  test "description must be a string", %{option: option} do
    assert_raise OptionDefinitionError, "description must be a string", fn ->
      option
      |> Map.put(:description, 123)
      |> Option.validate_definition()
    end
  end

  test "alias must be an atom", %{option: option} do
    assert_raise OptionDefinitionError, "alias must be an atom", fn ->
      option
      |> Map.put(:alias, "f")
      |> Option.validate_definition()
    end
  end

  test "keep cannot be used with type count", %{option: option} do
    assert_raise OptionDefinitionError, "keep cannot be used with type count", fn ->
      option
      |> Map.put(:keep, true)
      |> Map.put(:type, :count)
      |> Option.validate_definition()
    end
  end

  test "keep must be a boolean", %{option: option} do
    assert_raise OptionDefinitionError, "keep must be a boolean", fn ->
      option
      |> Map.put(:keep, "true")
      |> Option.validate_definition()
    end
  end

  test "allowed_values cannot be used with types boolean and count", %{option: option} do
    assert_raise OptionDefinitionError,
                 "allowed_values cannot be used with types boolean and count",
                 fn ->
                   option
                   |> Map.put(:type, :boolean)
                   |> Option.validate_definition()
                 end
  end

  test "all values in allowed_values must be of the same type of option", %{option: option} do
    assert_raise OptionDefinitionError, ~r/^all values in allowed_values must be of type/, fn ->
      option
      |> Map.put(:allowed_values, ["test", :assert, true])
      |> Option.validate_definition()
    end
  end

  test "allowed_values must be a list", %{option: option} do
    assert_raise OptionDefinitionError, "allowed_values must be a list", fn ->
      option
      |> Map.put(:allowed_values, "test")
      |> Option.validate_definition()
    end
  end

  test "default value must be of the same type of option", %{option: option} do
    assert_raise OptionDefinitionError, ~r/^default value must be of type/, fn ->
      option
      |> Map.put(:allowed_values, nil)
      |> Map.put(:default, 123)
      |> Option.validate_definition()
    end
  end

  test "default value must be included in allowed_values", %{option: option} do
    assert_raise OptionDefinitionError, "default value must be included in allowed_values", fn ->
      option
      |> Map.put(:default, "unknown")
      |> Option.validate_definition()
    end
  end

  test "fill default values", %{options: options, parsed: parsed} do
    expected = parsed ++ [limit: 5, format: "table"]

    assert expected ==
             Option.default(options, parsed)
  end

  test "don't fill default values for already informed values", %{
    options: options,
    parsed: parsed
  } do
    expected = parsed ++ [limit: 10, format: "json"]

    assert expected ==
             Option.default(options, parsed ++ [limit: 10, format: "json"])
  end

  test "group identical options into list", %{parsed: parsed} do
    assert [filter: ["elixir", "metaprogramming", "do_it"]] == Option.group(parsed)
  end

  test "parse input options", %{options: options, parsed: parsed} do
    assert {:ok, _} = Option.parse_input(options, parsed)
  end

  test "valid input value option - integer" do
    option = %Option{name: :test, type: :integer, description: "Test"}
    assert {%Option{}, 10} = Option.validate_input_value({option, "10"})
  end

  test "invalid input value option - integer" do
    option = %Option{name: :test, type: :integer, description: "Test"}
    assert {%Option{}, {:error, _}} = Option.validate_input_value({option, "10i"})
  end

  test "valid input value option - float" do
    option = %Option{name: :test, type: :float, description: "Test"}
    assert {%Option{}, 11.1} = Option.validate_input_value({option, 11.1})
  end

  test "valid input value option - valid string float" do
    option = %Option{name: :test, type: :float, description: "Test"}
    assert {%Option{}, 11.1} = Option.validate_input_value({option, "11.1"})
  end

  test "invalid input value option - float" do
    option = %Option{name: :test, type: :float, description: "Test"}
    assert {%Option{}, {:error, _}} = Option.validate_input_value({option, "11.1i"})
  end

  test "invalid input value option list" do
    option = %Option{name: :test, type: :float, description: "Test"}

    assert {%Option{}, {:error, _}} =
             Option.validate_input_value({option, ["33.3", "22.2i", "11.1"]})
  end

  test "valid input options", %{options: options, parsed: parsed} do
    {:ok, parsed_options} = Option.parse_input(options, parsed)
    assert {:ok, _} = Option.validate_input(options, parsed_options)
  end

  test "propagate error for valid input value options", %{option: option} do
    assert {%Option{}, {:error, _}} =
             Option.validate_input_value({option, {:error, "invalid option"}})
  end

  test "valid input allowed_values option", %{option: option} do
    assert {%Option{}, _} = Option.validate_input_allowed_values({option, "test"})
  end

  test "invalid input allowed_values option", %{option: option} do
    assert {%Option{}, {:error, _}} = Option.validate_input_allowed_values({option, "test123"})
  end

  test "valid input allowed_values option - list", %{option: option} do
    assert {%Option{}, _} = Option.validate_input_allowed_values({option, ["test", "assert"]})
  end

  test "invalid input allowed_values option - list", %{option: option} do
    assert {%Option{}, {:error, _}} =
             Option.validate_input_allowed_values({option, ["test", "assert", "none"]})
  end

  test "propagate error for valid input allowed_values options", %{option: option} do
    assert {%Option{}, {:error, _}} =
             Option.validate_input_allowed_values({option, {:error, "invalid option"}})
  end

  test "valid input when there are no defined options" do
    assert {:ok, []} = Option.validate_input([], {})
  end

  test "invalid input options", %{options: options, parsed: parsed} do
    {:ok, parsed_options} = Option.parse_input(options, parsed)

    assert {:error, _} =
             Option.validate_input(
               options,
               List.keyreplace(parsed_options, :limit, 0, {:limit, "5i"})
             )
  end
end
