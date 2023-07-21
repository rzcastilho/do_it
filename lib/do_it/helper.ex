defmodule DoIt.Helper do
  @moduledoc """
  DoIt helper functions.
  """

  @doc """
  Validates if all allowed values are of the same type.

  ## Examples

    iex> DoIt.Helper.validate_list_type([0, 1, 2, 3], :integer)
    true

    iex> DoIt.Helper.validate_list_type([0, 1, 2.1, 3], :integer)
    false

    iex> DoIt.Helper.validate_list_type([0.1, 1.1, 2.1, 3.1], :float)
    true

    iex> DoIt.Helper.validate_list_type([0.1, 1.1, 2, 3.1], :float)
    false

    iex> DoIt.Helper.validate_list_type(["warn", "error", "info", "debug"], :string)
    true

    iex> DoIt.Helper.validate_list_type(["warn", "error", "info", 0], :string)
    false

    iex> DoIt.Helper.validate_list_type(["warn", "error", "info", "debug"], :unknown)
    false
  """
  def validate_list_type(list, type) do
    case type do
      :string -> Enum.all?(list, &is_binary/1)
      :integer -> Enum.all?(list, &is_integer/1)
      :float -> Enum.all?(list, &is_float/1)
      _ -> false
    end
  end
end
