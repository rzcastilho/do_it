defmodule CoinGeckoCli do
  use DoIt.MainCommand,
    description: "CoinGecko CLI"

  command(CoinGeckoCli.Commands.List)
end
