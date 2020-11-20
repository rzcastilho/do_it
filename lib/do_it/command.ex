defmodule DoIt.Command do
  @moduledoc false

  defmodule Param do
    defstruct name: nil,
              description: nil,
              regex: nil,
              allowed_values: nil
  end

  defmodule Flag do
    defstruct name: nil,
              type: nil,
              description: nil,
              alias: nil,
              required: false,
              default: nil
  end

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__), only: [param: 2, param: 3, flag: 3, flag: 4]
      @behaviour DoIt.Runner

      Module.register_attribute(__MODULE__, :command, accumulate: false, persist: true)

      case List.keyfind(unquote(opts), :command, 0) do
        {:command, command} ->
          Module.put_attribute(__MODULE__, :command, command)

        _ ->
          Module.put_attribute(
            __MODULE__,
            :command,
            __ENV__.module
            |> Atom.to_string()
            |> String.split(".")
            |> List.last()
            |> Macro.underscore()
          )
      end

      Module.put_attribute(__MODULE__, :description, unquote(opts)[:description])

      Module.register_attribute(__MODULE__, :params, accumulate: true)
      Module.register_attribute(__MODULE__, :flags, accumulate: true)
      Module.register_attribute(__MODULE__, :strict, accumulate: true)
      Module.register_attribute(__MODULE__, :aliases, accumulate: true)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def command(), do: {@command, @description}

      def help() do
        EEx.eval_file(
          "lib/do_it/template/help.eex",
          app: Application.get_application(__MODULE__),
          command: @command,
          description: @description,
          params: @params,
          flags: @flags
        )
      end

      def do_it(args) do
        case OptionParser.parse(args, strict: @strict, aliases: @aliases) do
          {parsed_flags, parsed_params, []} ->
            run(parsed_params, parsed_flags, %{
              params: Enum.into(@params, %{}),
              flags: Enum.into(@flags, %{})
            })

          _ ->
            help()
        end
      end
    end
  end

  defmacro flag(name, type, description, opts \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :flags,
        {unquote(name),
         struct(
           %Flag{name: unquote(name), type: unquote(type), description: unquote(description)},
           unquote(opts)
         )}
      )

      Module.put_attribute(__MODULE__, :strict, {unquote(name), unquote(type)})

      case List.keymember?(unquote(opts), :alias, 0) do
        true ->
          Module.put_attribute(__MODULE__, :aliases, {unquote(opts[:alias]), unquote(name)})

        _ ->
          nil
      end
    end
  end

  defmacro param(name, description, opts \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :params,
        {unquote(name),
         struct(
           %Param{name: unquote(name), description: unquote(description)},
           unquote(opts)
         )}
      )
    end
  end
end
