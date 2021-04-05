defmodule DoIt.Command do
  @moduledoc false

  alias DoIt.{Argument, Option}

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__), only: [argument: 3, argument: 4, option: 3, option: 4]
      @behaviour DoIt.Runner
      alias DoIt.Commfig

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

      case List.keyfind(unquote(opts), :description, 0) do
        {:description, description} ->
          Module.put_attribute(__MODULE__, :description, description)

        _ ->
          raise(DoIt.CommandDefinitionError, "description is required for command definition")
      end

      Module.register_attribute(__MODULE__, :arguments, accumulate: true)
      Module.register_attribute(__MODULE__, :options, accumulate: true)
      Module.register_attribute(__MODULE__, :strict, accumulate: true)
      Module.register_attribute(__MODULE__, :aliases, accumulate: true)

      Module.put_attribute(__MODULE__, :options, %Option{name: :help, type: :boolean, description: "Print usage"})

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def command(), do: {@command, @description}

      def help() do
        DoIt.Output.print_help(
          app: Application.get_application(__MODULE__),
          command: @command,
          description: @description,
          arguments: @arguments,
          options: @options
        )
      end

      def do_it(args, context) do
        case OptionParser.parse(args, strict: @strict, aliases: @aliases) do
          {options, arguments, []} ->
            with {:ok, parsed_arguments} <- Argument.parse_input(@arguments, arguments),
                 {:ok, parsed_options} <- Option.parse_input(@options, options),
                 {:ok, validated_arguments} <-
                   Argument.validate_input(@arguments, parsed_arguments),
                 {:ok, validated_options} <- Option.validate_input(@options, parsed_options) do
              run(Enum.into(validated_arguments, %{}), Enum.into(validated_options, %{}), context)
            else
              {:error, message} ->
                DoIt.Output.print_errors(message)
                help()
            end

          {_, _, invalid_options} ->
            DoIt.Output.print_invalid_options(@command, invalid_options)

            help()
        end
      end
    end
  end

  defmacro argument(name, type, description, opts \\ []) do
    quote do
      argument =
        struct(
          %Argument{name: unquote(name), type: unquote(type), description: unquote(description)},
          unquote(opts)
        )
        |> Argument.validate_definition()

      Module.put_attribute(__MODULE__, :arguments, argument)
    end
  end

  defmacro option(name, type, description, opts \\ []) do
    quote do
      option =
        struct(
          %Option{name: unquote(name), type: unquote(type), description: unquote(description)},
          unquote(opts)
        )
        |> Option.validate_definition()

      Module.put_attribute(__MODULE__, :options, option)

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
end
