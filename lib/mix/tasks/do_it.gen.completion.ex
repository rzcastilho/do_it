defmodule Mix.Tasks.DoIt.Gen.Completion do
  use Mix.Task

  @shortdoc "Generates shell completion scripts for your DoIt CLI application"

  @moduledoc """
  Generates shell completion scripts for your DoIt CLI application.

  This task helps you generate completion scripts for popular shells and optionally
  save them to appropriate locations.

  ## Usage

      mix do_it.gen.completion [options]

  ## Options

    * `--shell` (`-s`) - Shell to generate completion for (bash, fish, zsh)
    * `--output` (`-o`) - Output file path (defaults to stdout)
    * `--install` (`-i`) - Show installation instructions instead of generating script
    * `--main-module` (`-m`) - Main module to use (auto-detected if not specified)
    * `--app-name` (`-a`) - Application name (defaults to app name from mix.exs)

  ## Examples

      # Generate bash completion script to stdout
      mix do_it.gen.completion --shell bash

      # Generate fish completion and save to file
      mix do_it.gen.completion --shell fish --output ~/.config/fish/completions/myapp.fish

      # Show installation instructions for zsh
      mix do_it.gen.completion --shell zsh --install

      # Generate for specific main module
      mix do_it.gen.completion --shell bash --main-module MyApp.CLI
  """

  alias DoIt.Completion

  def run(args) do
    {opts, _, invalid} = OptionParser.parse(args,
      switches: [
        shell: :string,
        output: :string,
        install: :boolean,
        main_module: :string,
        app_name: :string,
        help: :boolean
      ],
      aliases: [
        s: :shell,
        o: :output,
        i: :install,
        m: :main_module,
        a: :app_name,
        h: :help
      ]
    )

    if opts[:help] do
      print_help()
      :ok
    else

      if invalid != [] do
        Mix.shell().error("Invalid options: #{Enum.join(Enum.map(invalid, &elem(&1, 0)), ", ")}")
        print_help()
        System.halt(1)
      end

      shell = opts[:shell] || "bash"
      
      unless shell in ["bash", "fish", "zsh"] do
        Mix.shell().error("Unsupported shell: #{shell}. Supported shells: bash, fish, zsh")
        System.halt(1)
      end

      if opts[:install] do
        show_installation_instructions(shell, opts)
      else
        generate_completion_script(shell, opts)
      end
    end
  end

  defp generate_completion_script(shell, opts) do
    # Ensure the project is compiled
    Mix.Task.run("compile")
    
    main_module = get_main_module(opts[:main_module])
    app_name = opts[:app_name] || get_app_name()

    unless main_module do
      Mix.shell().error("Could not determine main module. Please specify with --main-module")
      System.halt(1)
    end

    unless Code.ensure_loaded?(main_module) do
      Mix.shell().error("Main module #{main_module} not found or not compiled")
      System.halt(1)
    end

    unless function_exported?(main_module, :command, 0) do
      Mix.shell().error("Module #{main_module} does not appear to be a DoIt.MainCommand")
      System.halt(1)
    end

    script = case shell do
      "bash" -> Completion.generate_bash_completion(main_module, app_name)
      "fish" -> Completion.generate_fish_completion(main_module, app_name)
      "zsh" -> Completion.generate_zsh_completion(main_module, app_name)
    end

    if output_file = opts[:output] do
      output_dir = Path.dirname(output_file)
      
      unless File.exists?(output_dir) do
        case Mix.shell().yes?("Directory #{output_dir} does not exist. Create it?") do
          true -> File.mkdir_p!(output_dir)
          false -> 
            Mix.shell().error("Cannot write to #{output_file}")
            System.halt(1)
        end
      end

      File.write!(output_file, script)
      Mix.shell().info("Generated #{shell} completion script: #{output_file}")
      
      if shell == "fish" do
        Mix.shell().info("Fish completion is now ready to use (restart your shell or run 'exec fish')")
      else
        Mix.shell().info("To enable completion, source this file or add it to your shell's configuration")
      end
    else
      IO.puts(script)
    end
  end

  defp show_installation_instructions(shell, opts) do
    app_name = opts[:app_name] || get_app_name()
    instructions = Completion.get_installation_instructions(app_name, shell)
    IO.puts(instructions)
  end

  defp get_main_module(nil) do
    # Try to auto-detect main module from escript configuration
    case Mix.Project.config()[:escript] do
      nil -> 
        # Try to find modules that use DoIt.MainCommand
        find_main_command_modules() |> List.first()
      escript_config ->
        escript_config[:main_module]
    end
  end

  defp get_main_module(module_string) when is_binary(module_string) do
    try do
      String.to_existing_atom("Elixir.#{module_string}")
    rescue
      ArgumentError ->
        try do
          String.to_existing_atom(module_string)
        rescue
          ArgumentError -> nil
        end
    end
  end

  defp find_main_command_modules do
    # Get all compiled modules and find those using DoIt.MainCommand
    case :application.get_key(Mix.Project.config()[:app], :modules) do
      {:ok, modules} ->
        modules
        |> Enum.filter(fn module ->
          Code.ensure_loaded?(module) and 
          function_exported?(module, :command, 0) and
          function_exported?(module, :main, 1)
        end)
      _ ->
        []
    end
  end

  defp get_app_name do
    Mix.Project.config()[:app] |> to_string()
  end

  defp print_help do
    IO.puts(@moduledoc)
  end
end