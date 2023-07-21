defmodule CoinGeckoCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :coin_gecko_cli,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CoinGeckoCli, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:do_it, path: "../../"},
      {:burrito, github: "burrito-elixir/burrito"},
      {:tableize, "~> 0.1.0"}
    ]
  end

  def releases do
    [
      coin_gecko_cli: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos: [os: :darwin, cpu: :x86_64],
            linux: [os: :linux, cpu: :x86_64],
            #windows: [os: :windows, cpu: :x86_64]
          ],
        ]
      ]
    ]
  end
end
