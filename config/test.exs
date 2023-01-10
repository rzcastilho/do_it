import Config

config :do_it, DoIt.Commfig,
  dirname: System.tmp_dir(),
  filename: "do_it_#{ExUnit.configuration()[:seed]}_test.json"
