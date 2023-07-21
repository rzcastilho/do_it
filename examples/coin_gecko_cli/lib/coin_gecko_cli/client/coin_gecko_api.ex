defmodule CoinGeckoCli.Client.CoinGeckoApi do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://api.coingecko.com/api/v3")
  plug(Tesla.Middleware.JSON, engine_opts: [keys: :atoms])

  def ping() do
    get("/ping")
    |> parse_response()
  end

  def coins_list(include_platform \\ false) do
    get("/coins/list?include_platform=#{include_platform}")
    |> parse_response()
  end

  def coins_categories_list() do
    get("/coins/categories/list")
    |> parse_response()
  end

  def exchanges_list() do
    get("/exchanges/list")
    |> parse_response()
  end

  def derivatives_exchanges_list() do
    get("/derivatives/exchanges/list")
    |> parse_response()
  end

  def exchange_rates() do
    get("/exchange_rates")
    |> parse_response()
  end

  def simple_supported_vs_currencies() do
    get("/simple/supported_vs_currencies")
    |> parse_response()
  end

  defp parse_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp parse_response({:ok, %Tesla.Env{body: body}}) do
    {:error, body}
  end

  defp parse_response({:error, any}) do
    {:error, any}
  end

end
