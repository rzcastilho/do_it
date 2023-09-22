defmodule Mix.Tasks.DoIt.Config.Init do
  use Mix.Task

  import Mix.Generator

  @shortdoc "Initializes DoIt persistent configuration"

  @moduledoc """
  Initializes DoIt persistent configuration.

  ## Examples

      $ mix do_it.config.init
  """

  embed_template(:config, """
  config :do_it, DoIt.Commfig,
    dirname: System.tmp_dir(),
    filename: "<%= @app %>.json"
  """)

  @impl true
  def run(_args) do
    config = Mix.Project.config()
    config_first_line = "import Config"
    config_path = config[:config_path] || "config/config.exs"
    app = config[:app] || :YOUR_APP_NAME
    opts = [app: app]

    case File.read(config_path) do
      {:ok, contents} ->
        new_contents = config_first_line <> "\n\n" <> config_template(opts)
        Mix.shell().info([:green, "* updating ", :reset, config_path])
        File.write!(config_path, String.replace(contents, config_first_line, new_contents))

      {:error, _} ->
        create_file(config_path, "import Config\n\n" <> config_template(opts))
    end
  end
end
