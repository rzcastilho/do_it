defmodule DoIt.MainCommand do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      Module.register_attribute(__MODULE__, :commands, accumulate: true, persist: false)

      Module.register_attribute(__MODULE__, :command_descriptions,
        accumulate: true,
        persist: false
      )

      case List.keyfind(unquote(opts), :description, 0) do
        {:description, description} ->
          Module.put_attribute(__MODULE__, :description, description)

        _ ->
          raise(
            DoIt.MainCommandDefinitionError,
            "description is required for main command definition"
          )
      end

      case List.keyfind(unquote(opts), :version, 0) do
        nil -> Module.put_attribute(__MODULE__, :version, {:version, unquote(version_number())})
        version -> Module.put_attribute(__MODULE__, :version, version)
      end

      import unquote(__MODULE__), only: [command: 1]
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    compile(Module.get_attribute(env.module, :commands))
  end

  def compile([]), do: raise(DoIt.CommandDefinitionError, message: "define at least a command")

  def compile(commands) do
    commands_ast =
      for module <- commands do
        with {command, _} <- module.command() do
          quote do
            def main([unquote(command) | args]) do
              apply(String.to_existing_atom("#{unquote(module)}"), :do_it, [
                args,
                %{
                  env: System.get_env(),
                  config: DoIt.Commfig.get_data()
                }
              ])
            end
          end
        end
      end

    quote do
      def help() do
        DoIt.Output.print_help(
          app: Application.get_application(__MODULE__),
          commands: @command_descriptions,
          main_description: @description
        )
      end

      gen_app_callback? =
        case Code.ensure_compiled(Burrito.Util.Args) do
          {:module, _module} -> true
          {:error, _reason} -> false
        end

      if gen_app_callback? do
        def start(_type, _args) do
          Burrito.Util.Args.get_arguments()
          |> main()

          System.halt(0)
        end
      end

      def main(["version" | _]), do: IO.puts("#{inspect(@version)}")
      def main(["help" | _]), do: help()

      unquote(commands_ast)

      def main([unknown | _]) do
        IO.puts("invalid command #{unknown}")
        help()
      end

      def main([]) do
        IO.puts("no command provided")
        help()
      end

      def main(_), do: help()
      def main(), do: help()
    end
  end

  defmacro command(module) do
    quote do
      @commands unquote(module)
      with {name, description} <- unquote(module).command() do
        @command_descriptions %{name: name, description: description}
      end
    end
  end

  def version_number() do
    case File.read!("mix.exs") |> Code.string_to_quoted!() do
      {:defmodule, _, [{:__aliases__, _, [_, :MixProject]}, [do: {:__block__, [], do_block}]]} ->
        case do_block
             |> find_project_func()
             |> List.keyfind(:version, 0, :undefined) do
          {:version, version} when is_binary(version) ->
            version

          {:version, {:@, _, _}} ->
            case do_block
                 |> find_module_attribute(:version)
                 |> List.first() do
              nil -> :undefined
              version -> version
            end

          _ ->
            :undefined
        end

      _ ->
        :undefined
    end
  end

  def find_project_func([{:def, _, [{:project, _, nil}, [do: body]]} | _]) do
    body
  end

  def find_project_func([_ | rest]) do
    find_project_func(rest)
  end

  def find_project_func([]), do: []

  def find_module_attribute([{:@, _, [{attribute, _, value}]} | _], attribute) do
    value
  end

  def find_module_attribute([_ | rest], attr) do
    find_module_attribute(rest, attr)
  end

  def find_module_attribute([], _), do: []
end
