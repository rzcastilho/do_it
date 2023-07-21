defmodule CoinGeckoCli.Commands.List do
  use DoIt.Command,
    description: "List assets"

  alias CoinGeckoCli.Client.CoinGeckoApi

  argument(:asset, :string, "Asset name", allowed_values: ["coins", "exchanges", "categories", "derivatives_exchanges"])

  option(:page, :integer, "Page number", alias: :n, default: 1)
  option(:size, :integer, "Page size", alias: :s, default: 10)

  def run(%{asset: asset}, %{page: page_number, size: page_size}, _) do
    {:ok, data} =
      case asset do
        "coins" ->
          CoinGeckoApi.coins_list()
        "exchanges" ->
          CoinGeckoApi.exchanges_list()
        "categories" ->
          CoinGeckoApi.coins_categories_list()
        "derivatives_exchanges" ->
          CoinGeckoApi.derivatives_exchanges_list()
      end
    IO.puts("Listing #{asset |> String.upcase() |> String.replace("_", " ")} assets...\n")
    data
    |> Enum.map(&Map.to_list/1)
    |> Enum.drop((page_number - 1) * page_size)
    |> Enum.take(page_size)
    |> Tableize.print()
    IO.puts("\nPage Number: #{page_number}\nPage Size: #{page_size}\nTotal: #{Enum.count(data)}\n")
  end
end
