defmodule DoItTest do
  use ExUnit.Case
  doctest DoIt

  test "greets the world" do
    assert DoIt.hello() == :world
  end
end
