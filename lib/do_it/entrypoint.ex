defmodule DoIt.Entrypoint do
  @moduledoc false

  defmacro __using__(_) do
    commands =
      walk()
      |> Enum.map(fn
        {name, %{command: command}} -> {name, String.downcase(command)}
        {name, _options} -> {name, name |> String.split(".") |> List.last() |> String.downcase()}
      end)
      |> Enum.map(fn
        {module, command} ->
          quote do
            def main([unquote(command) | args]) do
              apply(String.to_existing_atom("Elixir.#{unquote(module)}"), :do_it, [args, %{env: System.get_env()}])
            end
          end
      end)

    quote do

      def main(["version"|_]) do
        IO.puts Mix.Project.config()[:version]
      end

      unquote(commands)

      def main([]), do: IO.puts "Help"
      def main(_), do: IO.puts "Help"
      def main(), do: IO.puts "Help"

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
end
