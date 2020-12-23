defmodule DoIt.Command do
  @moduledoc false

  alias DoIt.{Param, Flag}

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__), only: [param: 3, param: 4, flag: 3, flag: 4]
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
        DoIt.Helper.print_help(
          app: Application.get_application(__MODULE__),
          command: @command,
          description: @description,
          params: @params,
          flags: @flags
        )
      end

      def do_it(args, context) do
        case OptionParser.parse(args, strict: @strict, aliases: @aliases) do
          {flags, params, []} ->
            with {:ok, parsed_params} <- Param.parse_input(@params, params),
                 {:ok, parsed_flags} <- Flag.parse_input(@flags, flags),
                 {:ok, validated_params} <- Param.validate_input(@params, parsed_params),
                 {:ok, validated_flags} <- Flag.validate_input(@flags, parsed_flags) do
              run(validated_params, validated_flags, context)
            else
              {:error, _} -> help()
            end
          _ ->
            help()
        end
      end
    end
  end

  defmacro flag(name, type, description, opts \\ []) do
    quote do
      flag =
        struct(
          %Flag{name: unquote(name), type: unquote(type), description: unquote(description)},
          unquote(opts)
        )
        |> Flag.validate_definition()

      Module.put_attribute(__MODULE__, :flags, flag)

      case List.keyfind(unquote(opts), :keep, 0) do
        {:keep, true} ->
          Module.put_attribute(__MODULE__, :strict, {unquote(name), [unquote(type), :keep]})

        _ ->
          Module.put_attribute(__MODULE__, :strict, {unquote(name), unquote(type)})
      end

      case List.keymember?(unquote(opts), :alias, 0) do
        true ->
          Module.put_attribute(__MODULE__, :aliases, {unquote(opts[:alias]), unquote(name)})

        _ ->
          nil
      end
    end
  end

  defmacro param(name, type, description, opts \\ []) do
    quote do
      param =
        struct(
          %Param{name: unquote(name), type: unquote(type), description: unquote(description)},
          unquote(opts)
        )
        |> Param.validate_definition()

      Module.put_attribute(__MODULE__, :params, param)
    end
  end
end
