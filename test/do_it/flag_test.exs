defmodule DoIt.FlagTest do
  @moduledoc false
  use ExUnit.Case
  doctest DoIt.Flag

  alias DoIt.Flag
  alias DoIt.FlagDefinitionError

  setup_all do
    {
      :ok,
      flag: %Flag{
        name: :test,
        type: :string,
        description: "Flag test description",
        alias: :t,
        default: "test",
        keep: false,
        allowed_values: ["test", "assert", "refute"]
      },
      flags: [
        %DoIt.Flag{
          alias: nil,
          allowed_values: nil,
          default: 5,
          description: "Max number of search results",
          keep: nil,
          name: :limit,
          type: :integer
        },
        %DoIt.Flag{
          alias: nil,
          allowed_values: ["table", "csv", "json"],
          default: "table",
          description: "Output format",
          keep: nil,
          name: :format,
          type: :string
        },
        %DoIt.Flag{
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

  test "valid flag definition", %{flag: flag} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: _, allowed_values: _} =
             Flag.validate_definition(flag)
  end

  test "valid flag definition of type integer", %{flag: flag} do
    assert %{
             name: _,
             type: _,
             description: _,
             alias: _,
             default: _,
             keep: nil,
             allowed_values: nil
           } =
             flag
             |> Map.put(:type, :integer)
             |> Map.put(:default, 1)
             |> Map.put(:allowed_values, nil)
             |> Map.put(:keep, nil)
             |> Flag.validate_definition()
  end

  test "valid flag definition of type integer with allowed_values", %{flag: flag} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: nil, allowed_values: _} =
             flag
             |> Map.put(:type, :integer)
             |> Map.put(:default, 1)
             |> Map.put(:allowed_values, [1, 2, 3, 4])
             |> Map.put(:keep, nil)
             |> Flag.validate_definition()
  end

  test "valid flag definition of type float", %{flag: flag} do
    assert %{
             name: _,
             type: _,
             description: _,
             alias: _,
             default: _,
             keep: nil,
             allowed_values: nil
           } =
             flag
             |> Map.put(:type, :float)
             |> Map.put(:default, 1.5)
             |> Map.put(:allowed_values, nil)
             |> Map.put(:keep, nil)
             |> Flag.validate_definition()
  end

  test "valid flag definition of type float with allowed_values", %{flag: flag} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: nil, allowed_values: _} =
             flag
             |> Map.put(:type, :float)
             |> Map.put(:default, 1.5)
             |> Map.put(:allowed_values, [1.0, 1.25, 1.5, 1.75, 2.0])
             |> Map.put(:keep, nil)
             |> Flag.validate_definition()
  end

  test "valid flag definition of type boolean", %{flag: flag} do
    assert %{
             name: _,
             type: _,
             description: _,
             alias: _,
             default: _,
             keep: nil,
             allowed_values: nil
           } =
             flag
             |> Map.put(:type, :boolean)
             |> Map.put(:default, true)
             |> Map.put(:keep, nil)
             |> Map.put(:allowed_values, nil)
             |> Flag.validate_definition()
  end

  test "valid flag definition of type count", %{flag: flag} do
    assert %{
             name: _,
             type: _,
             description: _,
             alias: _,
             default: _,
             keep: nil,
             allowed_values: nil
           } =
             flag
             |> Map.put(:type, :count)
             |> Map.put(:default, 10)
             |> Map.put(:keep, nil)
             |> Map.put(:allowed_values, nil)
             |> Flag.validate_definition()
  end

  test "valid flag definition without alias", %{flag: flag} do
    assert %{name: _, type: _, description: _, alias: nil, default: _, keep: _, allowed_values: _} =
             flag
             |> Map.put(:alias, nil)
             |> Flag.validate_definition()
  end

  test "valid flag definition without allowed_values", %{flag: flag} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: _, allowed_values: nil} =
             flag
             |> Map.put(:allowed_values, nil)
             |> Flag.validate_definition()
  end

  test "valid flag definition without default", %{flag: flag} do
    assert %{name: _, type: _, description: _, alias: _, default: nil, keep: _, allowed_values: _} =
             flag
             |> Map.put(:default, nil)
             |> Flag.validate_definition()
  end

  test "valid flag definition without keep", %{flag: flag} do
    assert %{name: _, type: _, description: _, alias: _, default: _, keep: nil, allowed_values: _} =
             flag
             |> Map.put(:keep, nil)
             |> Flag.validate_definition()
  end

  test "name is required for flag definition", %{flag: flag} do
    assert_raise FlagDefinitionError, "name is required for flag definition", fn ->
      flag
      |> Map.put(:name, nil)
      |> Flag.validate_definition()
    end
  end

  test "name must be an atom", %{flag: flag} do
    assert_raise FlagDefinitionError, "name must be an atom", fn ->
      flag
      |> Map.put(:name, "test")
      |> Flag.validate_definition()
    end
  end

  test "type is required for flag definition", %{flag: flag} do
    assert_raise FlagDefinitionError, "type is required for flag definition", fn ->
      flag
      |> Map.put(:type, nil)
      |> Flag.validate_definition()
    end
  end

  test "unrecognized flag type", %{flag: flag} do
    assert_raise FlagDefinitionError, ~r/^unrecognized flag type/, fn ->
      flag
      |> Map.put(:type, :unknown)
      |> Flag.validate_definition()
    end
  end

  test "description is required for flag definition", %{flag: flag} do
    assert_raise FlagDefinitionError, "description is required for flag definition", fn ->
      flag
      |> Map.put(:description, nil)
      |> Flag.validate_definition()
    end
  end

  test "description must be a string", %{flag: flag} do
    assert_raise FlagDefinitionError, "description must be a string", fn ->
      flag
      |> Map.put(:description, 123)
      |> Flag.validate_definition()
    end
  end

  test "alias must be an atom", %{flag: flag} do
    assert_raise FlagDefinitionError, "alias must be an atom", fn ->
      flag
      |> Map.put(:alias, "f")
      |> Flag.validate_definition()
    end
  end

  test "keep cannot be used with type :count", %{flag: flag} do
    assert_raise FlagDefinitionError, "keep cannot be used with type :count", fn ->
      flag
      |> Map.put(:keep, true)
      |> Map.put(:type, :count)
      |> Flag.validate_definition()
    end
  end

  test "keep must be a boolean", %{flag: flag} do
    assert_raise FlagDefinitionError, "keep must be a boolean", fn ->
      flag
      |> Map.put(:keep, "true")
      |> Flag.validate_definition()
    end
  end

  test "allowed_values cannot be used with types :boolean and :count", %{flag: flag} do
    assert_raise FlagDefinitionError,
                 "allowed_values cannot be used with types :boolean and :count",
                 fn ->
                   flag
                   |> Map.put(:type, :boolean)
                   |> Flag.validate_definition()
                 end
  end

  test "all values in allowed_values must be of the same type of flag", %{flag: flag} do
    assert_raise FlagDefinitionError, ~r/^all values in allowed_values must be of type/, fn ->
      flag
      |> Map.put(:allowed_values, ["test", :assert, true])
      |> Flag.validate_definition()
    end
  end

  test "allowed_values must be a list", %{flag: flag} do
    assert_raise FlagDefinitionError, "allowed_values must be a list", fn ->
      flag
      |> Map.put(:allowed_values, "test")
      |> Flag.validate_definition()
    end
  end

  test "default value must be of the same type of flag", %{flag: flag} do
    assert_raise FlagDefinitionError, ~r/^default value must be of type/, fn ->
      flag
      |> Map.put(:allowed_values, nil)
      |> Map.put(:default, 123)
      |> Flag.validate_definition()
    end
  end

  test "default value must be included in allowed_values", %{flag: flag} do
    assert_raise FlagDefinitionError, "default value must be included in allowed_values", fn ->
      flag
      |> Map.put(:default, "unknown")
      |> Flag.validate_definition()
    end
  end

  test "fill default values", %{flags: flags, parsed: parsed} do
    expected = parsed ++ [limit: 5, format: "table"]

    assert expected ==
             Flag.default(flags, parsed)
  end

  test "don't fill default values for already informed values", %{flags: flags, parsed: parsed} do
    expected = parsed ++ [limit: 10, format: "json"]

    assert expected ==
             Flag.default(flags, parsed ++ [limit: 10, format: "json"])
  end

  test "group identical flags into list", %{parsed: parsed} do
    assert [filter: ["elixir", "metaprogramming", "do_it"]] == Flag.group(parsed)
  end

  test "parse input flags", %{flags: flags, parsed: parsed} do
    assert {:ok, _} = Flag.parse_input(flags, parsed)
  end

  test "valid input value flag - integer" do
    flag = %Flag{name: :test, type: :integer, description: "Test"}
    assert {%Flag{}, 10} = Flag.validate_input_value({flag, "10"})
  end

  test "invalid input value flag - integer" do
    flag = %Flag{name: :test, type: :integer, description: "Test"}
    assert {%Flag{}, {:error, _}} = Flag.validate_input_value({flag, "10i"})
  end

  test "valid input value flag - float" do
    flag = %Flag{name: :test, type: :float, description: "Test"}
    assert {%Flag{}, 11.1} = Flag.validate_input_value({flag, "11.1"})
  end

  test "invalid input value flag - float" do
    flag = %Flag{name: :test, type: :float, description: "Test"}
    assert {%Flag{}, {:error, _}} = Flag.validate_input_value({flag, "11.1i"})
  end

  test "invalid input value flag list" do
    flag = %Flag{name: :test, type: :float, description: "Test"}
    assert {%Flag{}, {:error, _}} = Flag.validate_input_value({flag, ["33.3", "22.2i", "11.1"]})
  end

  test "valid input flags", %{flags: flags, parsed: parsed} do
    {:ok, parsed_flags} = Flag.parse_input(flags, parsed)
    assert {:ok, _} = Flag.validate_input(flags, parsed_flags)
  end

  test "propagate error for valid input value flags", %{flag: flag} do
    assert {%Flag{}, {:error, _}} = Flag.validate_input_value({flag, {:error, "invalid flag"}})
  end

  test "valid input allowed_values flag", %{flag: flag} do
    assert {%Flag{}, _} = Flag.validate_input_allowed_values({flag, "test"})
  end

  test "invalid input allowed_values flag", %{flag: flag} do
    assert {%Flag{}, {:error, _}} = Flag.validate_input_allowed_values({flag, "test123"})
  end

  test "valid input allowed_values flag - list", %{flag: flag} do
    assert {%Flag{}, _} = Flag.validate_input_allowed_values({flag, ["test", "assert"]})
  end

  test "invalid input allowed_values flag - list", %{flag: flag} do
    assert {%Flag{}, {:error, _}} =
             Flag.validate_input_allowed_values({flag, ["test", "assert", "none"]})
  end

  test "propagate error for valid input allowed_values flags", %{flag: flag} do
    assert {%Flag{}, {:error, _}} =
             Flag.validate_input_allowed_values({flag, {:error, "invalid flag"}})
  end

  test "invalid input flags", %{flags: flags, parsed: parsed} do
    {:ok, parsed_flags} = Flag.parse_input(flags, parsed)

    assert {:error, _} =
             Flag.validate_input(flags, List.keyreplace(parsed_flags, :limit, 0, {:limit, "5i"}))
  end
end
