defmodule DoIt.MainCommand do
  @moduledoc false

  defmacro __using__(opts) do
    commands = walk()

    if Enum.empty?(commands),
      do: raise(DoIt.CommandDefinitionError, message: "define at least a command")

    main_functions =
      commands
      |> Enum.map(fn
        {name, %{command: command}} -> {name, String.downcase(command)}
        {name, _options} -> {name, name |> String.split(".") |> List.last() |> String.downcase()}
      end)
      |> Enum.map(fn
        {module, command} ->
          quote do
            def main([unquote(command) | args]) do
              apply(String.to_existing_atom("Elixir.#{unquote(module)}"), :do_it, [
                args,
                %{
                  env: System.get_env(),
                  config: DoIt.Commfig.get_data()
                }
              ])
            end
          end
      end)

    command_descriptions =
      commands
      |> Enum.map(fn
        {_, %{command: command, description: description}} ->
          quote do
            %{name: String.downcase(unquote(command)), description: unquote(description)}
          end

        {name, %{description: description}} ->
          quote do
            %{
              name: unquote(name) |> String.split(".") |> List.last() |> String.downcase(),
              description: unquote(description)
            }
          end
      end)

    quote do
      Module.put_attribute(__MODULE__, :main_functions, unquote(main_functions))

      Module.put_attribute(__MODULE__, :command_descriptions, unquote(command_descriptions))

      case List.keyfind(unquote(opts), :description, 0) do
        {:description, description} ->
          Module.put_attribute(__MODULE__, :description, description)

        _ ->
          raise(
            DoIt.MainCommandDefinitionError,
            "description is required for main command definition"
          )
      end

      Module.register_attribute(__MODULE__, :version, persist: true)

      case List.keyfind(unquote(opts), :version, 0) do
        nil -> Module.put_attribute(__MODULE__, :version, {:version, unquote(version_number())})
        version -> Module.put_attribute(__MODULE__, :version, version)
      end

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def help() do
        DoIt.Output.print_help(
          app: Application.get_application(__MODULE__),
          commands: @command_descriptions,
          main_description: @description
        )
      end

      def main(["version" | _]), do: IO.inspect(@version)
      def main(["help" | _]), do: help()

      @main_functions

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

  defp list_all(filepath), do: expand(File.ls(filepath), filepath)

  defp expand({:ok, files}, path) do
    files
    |> Enum.flat_map(&list_all("#{path}/#{&1}"))
    |> Enum.filter(&String.ends_with?(&1, ".ex"))
  end

  defp expand({:error, _}, path), do: [path]

  defp match_modules({:__block__, [], modules}), do: modules

  defp match_modules(modules), do: [modules]

  defp match_uses({:use, _, uses_list} = node, acc) do
    {node, acc ++ [uses_list]}
  end

  defp match_uses(node, acc), do: {node, acc}

  defp filter_commands(aliases) do
    aliases
    |> Enum.map(fn
      [{:__aliases__, _meta, [:DoIt, :Command]}, options] -> Enum.into(options, %{})
      [{:__aliases__, _meta, [:DoIt, :Command]}] -> %{}
      _ -> nil
    end)
    |> Enum.filter(fn
      nil -> false
      _ -> true
    end)
    |> List.first()
  end

  defp command_not_empty({_name, nil}), do: false

  defp command_not_empty({_name, []}), do: false

  defp command_not_empty({_name, _uses}), do: true

  def walk() do
    list_all("./lib")
    |> Enum.map(&File.read!/1)
    |> Enum.map(&Code.string_to_quoted!/1)
    |> Enum.flat_map(&match_modules/1)
    |> Enum.map(fn ast -> {Credo.Code.Module.name(ast), Macro.prewalk(ast, [], &match_uses/2)} end)
    |> Enum.map(fn {name, {_, uses}} -> {name, filter_commands(uses)} end)
    |> Enum.filter(&command_not_empty/1)
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

  def find_module_attribute([{:@, _, [{attribute, _, value}]} | _], attr)
      when attribute == attr do
    value
  end

  def find_module_attribute([_ | rest], attr) do
    find_module_attribute(rest, attr)
  end

  def find_module_attribute([], _), do: []
end
