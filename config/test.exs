use Mix.Config

config :do_it, DoIt.Commfig,
  dirname: System.tmp_dir(),
  filename: "cfg_#{ExUnit.configuration()[:seed]}.json"
