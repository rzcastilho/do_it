defmodule CoinGeckoCliTest do
  use ExUnit.Case
  doctest CoinGeckoCli

  test "greets the world" do
    assert CoinGeckoCli.hello() == :world
  end
end
