defmodule DoIt.CommfigTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias DoIt.Commfig

  setup_all do
    Commfig.set("test", "setup")
    on_exit(fn -> File.rm!(Commfig.get_file()) end)
    {:ok, Commfig.get_data()}
  end

  test "success getting dir name" do
    assert Application.get_env(:do_it, DoIt.Commfig)[:dirname] == Commfig.get_dir()
  end

  test "success getting file name" do
    assert Path.join(
             Application.get_env(:do_it, DoIt.Commfig)[:dirname],
             Application.get_env(:do_it, DoIt.Commfig)[:filename]
           ) == Commfig.get_file()
  end

  test "success getting data" do
    assert %{"test" => value} = Commfig.get_data()
    assert value == "setup"
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

  test "success getting key" do
    Commfig.set("msg", "Hello World Again!")
    assert "Hello World Again!" = Commfig.get("msg")
    assert %{"msg" => "Hello World Again!"} = Commfig.get_data()
  end

  test "success unsetting key" do
    Commfig.set("msg", "Another message!!!")
    assert "Another message!!!" = Commfig.get("msg")
    Commfig.unset("msg")
    assert %{} = Commfig.get_data()
  end
end
