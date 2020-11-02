defmodule DoIt.Command do
  @moduledoc false

  defmodule Flag do
    defstruct [
      name: nil,
      type: nil,
      description: nil,
      alias: nil,
      required: true,
      default: nil
    ]
  end

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__), only: [flag: 3, flag: 4]
      @behaviour DoIt.Runner

      case List.keyfind(unquote(opts), :name, 0) do
        {:name, name} -> Module.put_attribute(__MODULE__, :name, name)
        _ -> Module.put_attribute(__MODULE__, :name, __ENV__.module |> Atom.to_string() |> String.split(".") |> List.last() |> Macro.underscore())
      end

      Module.put_attribute(__MODULE__, :description, unquote(opts)[:description])

      Module.register_attribute(__MODULE__, :flags, accumulate: true)
      Module.register_attribute(__MODULE__, :strict, accumulate: true)
      Module.register_attribute(__MODULE__, :aliases, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do

      def help() do
        EEx.eval_file("lib/do_it/template/help.eex", action: @name, description: @description, flags: @flags)
      end

      def do_it(args) do
        case OptionParser.parse(args, [strict: @strict, aliases: @aliases]) do
          {opts, [], []} ->
            run(opts, Enum.into(@flags, %{}))
          _ ->
            help()
        end
      end

    end
  end

  defmacro flag(name, type, description, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :flags, {unquote(name), struct(%Flag{name: unquote(name), type: unquote(type), description: unquote(description)}, unquote(opts))})
      Module.put_attribute(__MODULE__, :strict, {unquote(name), unquote(type)})
      case List.keymember?(unquote(opts), :alias, 0) do
        true ->
          Module.put_attribute(__MODULE__, :aliases, {unquote(opts[:alias]), unquote(name)})
        _ ->
          nil
      end
    end
  end

end
