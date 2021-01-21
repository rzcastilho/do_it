defmodule DoIt.MixProject do
  use Mix.Project

  @source_url "https://github.com/rzcastilho/do_it"
  @version "0.1.0"

  def project do
    [
      app: :do_it,
      version: "0.1.0",
      deps: deps(),
      elixir: "~> 1.8",
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
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13", only: :test},
      {:credo, "~> 1.5"},
      {:jason, "~> 1.2"}
    ]
  end

  defp description() do
    """
    Elixir Command Line Interface Framework.

    A framework that helps to develop command line tools with Elixir.
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
