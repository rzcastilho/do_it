defmodule DoIt.Helper do
  @moduledoc false

  def validate_list_type(list, type) do
    case type do
      :string -> Enum.all?(list, &is_binary/1)
      :integer -> Enum.all?(list, &is_integer/1)
      :float -> Enum.all?(list, &is_float/1)
      _ -> false
    end
  end
end
