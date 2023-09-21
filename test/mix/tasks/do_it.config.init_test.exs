defmodule Mix.Tasks.DoIt.Config.InitTest do
  use ExUnit.Case

  import Mix.Tasks.DoIt.Config.Init, only: [run: 1]

  @tmp_path Path.expand(System.tmp_dir(), __DIR__)

  test "generate a new config file" do
    in_tmp("new_config", fn ->
      run([])

      assert_file("config/config.exs", """
      import Config

      config :do_it, DoIt.Commfig,
        dirname: System.tmp_dir(),
        filename: "do_it.json"
      """)
    end)
  end

  test "update an existing config file" do
    in_tmp("existing_config", fn ->
      File.mkdir_p!("config")

      File.write!("config/config.exs", """
      # Test
      import Config
      # Existing File
      """)

      run([])

      assert_file("config/config.exs", """
      # Test
      import Config

      config :do_it, DoIt.Commfig,
        dirname: System.tmp_dir(),
        filename: "do_it.json"

      # Existing File
      """)
    end)
  end

  defp in_tmp(path, fun) do
    path = Path.join(@tmp_path, path)
    File.rm_rf!(path)
    File.mkdir_p!(path)
    File.cd!(path, fun)
  end

  defp assert_file(file, match) do
    assert File.read!(file) =~ match
  end
end
