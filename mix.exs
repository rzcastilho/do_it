defmodule DoIt.MixProject do
  @moduledoc false

  use Mix.Project

  @source_url "https://github.com/rzcastilho/do_it"
  @version "0.5.0"

  def project do
    [
      app: :do_it,
      version: @version,
      deps: deps(),
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DoIt, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.3", only: :dev, runtime: false},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:castore, "~> 1.0", only: :test},
      {:credo, "~> 1.7"},
      {:jason, "~> 1.4"}
    ]
  end

  defp description() do
    """
    Elixir Command Line Interface Library.

    A library that helps to develop CLI tools with Elixir.
    """
  end

  defp package() do
    [
      maintainers: ["Rodrigo Zampieri Castilho"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "DoIt",
      source_ref: @version,
      canonical: "http://hexdocs.pm/do_it",
      source_url: @source_url,
      extras: ["README.md", "LICENSE"]
    ]
  end
end
