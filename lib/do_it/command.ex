defmodule DoIt.Command do
  @moduledoc false

  alias DoIt.{Argument, Option}

  defmacro __using__(opts) do
    quote do
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

      Module.register_attribute(__MODULE__, :subcommands, accumulate: true, persist: false)

      Module.register_attribute(__MODULE__, :subcommand_descriptions,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :arguments, accumulate: true)
      Module.register_attribute(__MODULE__, :options, accumulate: true)
      Module.register_attribute(__MODULE__, :strict, accumulate: true)
      Module.register_attribute(__MODULE__, :aliases, accumulate: true)

      Module.put_attribute(__MODULE__, :options, %Option{
        name: :help,
        type: :boolean,
        description: "Print this help"
      })

      Module.put_attribute(__MODULE__, :strict, {:help, :boolean})

      import unquote(__MODULE__),
        only: [subcommand: 1, argument: 3, argument: 4, option: 3, option: 4]

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    compile(Module.get_attribute(env.module, :subcommands), __CALLER__)
  end

  def compile([], caller) do
    caller_module = caller.module

    quote do
      @behaviour DoIt.Runner
      alias DoIt.Commfig

      def command(), do: {@command, @description}

      def help(%{breadcrumb: breadcrumb}) do
        DoIt.Output.print_help(
          commands: breadcrumb ++ [unquote(caller_module)],
          description: @description,
          arguments: @arguments,
          options: @options
        )
      end

      def do_it(args, context) do
        case OptionParser.parse(args, strict: @strict, aliases: @aliases) do
          {options, arguments, []} ->
            if {:help, true} in options do
              help(context)
            else
              with {:ok, parsed_arguments} <- Argument.parse_input(@arguments, arguments),
                   {:ok, parsed_options} <- Option.parse_input(@options, options),
                   {:ok, validated_arguments} <-
                     Argument.validate_input(@arguments, parsed_arguments),
                   {:ok, validated_options} <- Option.validate_input(@options, parsed_options) do
                run(
                  Enum.into(validated_arguments, %{}),
                  Enum.into(validated_options, %{}),
                  context
                )
              else
                {:error, message} ->
                  DoIt.Output.print_errors(message)
                  help(context)
              end
            end

          {_, _, invalid_options} ->
            DoIt.Output.print_invalid_options(@command, invalid_options)

            help(context)
        end
      end
    end
  end

  def compile(subcommands, caller) do
    caller_module = caller.module

    subcommands_ast =
      for module <- subcommands do
        with {subcommand, _} <- module.command() do
          quote do
            def do_it([unquote(subcommand) | args], context) do
              %{breadcrumb: breadcrumb} = context

              apply(String.to_existing_atom("#{unquote(module)}"), :do_it, [
                args,
                %{context | breadcrumb: breadcrumb ++ [unquote(caller.module)]}
              ])
            end
          end
        end
      end

    quote do
      def command(), do: {@command, @description}

      def help(%{breadcrumb: breadcrumb}) do
        DoIt.Output.print_help(
          commands: breadcrumb ++ [unquote(caller_module)],
          description: @description,
          subcommands: @subcommand_descriptions
        )
      end

      def do_it(["--help" | _], context), do: help(context)

      unquote(subcommands_ast)

      def do_it([unknown | _], context) do
        IO.puts("invalid subcommand #{unknown}")
        help(context)
      end

      def do_it([], context) do
        IO.puts("no subcommand provided")
        help(context)
      end
    end
  end

  defmacro subcommand(module) do
    quote do
      @subcommands unquote(module)
      with {name, description} <- unquote(module).command() do
        @subcommand_descriptions %{name: name, description: description}
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
