import Config

config :logger, :console,
  level: :error

config :do_it, DoIt.Commfig,
  dirname: System.tmp_dir(),
  filename: "coin_gecko_cli.json"
