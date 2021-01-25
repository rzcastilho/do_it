use Mix.Config

config :do_it, DoIt.Commfig,
       dirname: System.tmp_dir(),
       filename: "do_it_dev.json"
