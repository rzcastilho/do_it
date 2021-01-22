defmodule DoIt.CommfigTest do
  @moduledoc false
  use ExUnit.Case

  alias DoIt.Commfig

  setup_all do
    Commfig.set("test", "setup")
    on_exit(fn -> File.rm!(Commfig.get_file()) end)
    {:ok, Commfig.get_data()}
  end

  test "match previous configured key", %{"test" => value} do
    assert value == "setup"
  end

  test "error setting key - ArgumentError" do
    assert {:error, _message} = Commfig.set(["parent", "child"], true)
  end

  test "error setting key - FunctionClauseError" do
    assert {:error, _message} = Commfig.set(["test", "child"], true)
  end

  test "success setting key" do
    assert :ok = Commfig.set("message", "Hello World!")
    assert %{"message" => "Hello World!"} = Commfig.get_data()
  end
end
