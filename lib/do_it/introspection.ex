defmodule DoIt.Introspection do
  @moduledoc """
  Provides introspection capabilities for DoIt commands and their structure.

  This module enables analysis of command hierarchies, options, arguments,
  and other metadata needed for features like auto-completion.
  """

  @doc """
  Gets all top-level commands from a MainCommand module.

  Returns a list of command names as strings.
  """
  def get_all_commands(main_module) do
    case main_module.__info__(:attributes) do
      attributes when is_list(attributes) ->
        attributes
        |> Keyword.get_values(:commands)
        |> List.flatten()
        |> Enum.map(fn module ->
          {command_name, _} = module.command()
          command_name
        end)

      _ ->
        []
    end
  end

  @doc """
  Gets all subcommands from a Command module.

  Returns a list of subcommand names as strings.
  """
  def get_subcommands(command_module) do
    if function_exported?(command_module, :__info__, 1) do
      case command_module.__info__(:attributes) do
        attributes when is_list(attributes) ->
          attributes
          |> Keyword.get_values(:subcommands)
          |> List.flatten()
          |> Enum.map(fn module ->
            {subcommand_name, _} = module.command()
            subcommand_name
          end)

        _ ->
          []
      end
    else
      []
    end
  end

  @doc """
  Gets all options from a Command module.

  Returns a list of DoIt.Option structs.
  """
  def get_command_options(command_module) do
    if function_exported?(command_module, :__info__, 1) do
      case command_module.__info__(:attributes) do
        attributes when is_list(attributes) ->
          attributes
          |> Keyword.get_values(:options)
          |> List.flatten()

        _ ->
          []
      end
    else
      []
    end
  end

  @doc """
  Gets all option flags (--name and -alias) from a Command module.

  Returns a list of option flags as strings.
  """
  def get_command_option_flags(command_module) do
    get_command_options(command_module)
    |> Enum.flat_map(fn option ->
      flags = ["--#{option.name}"]

      if option.alias do
        flags ++ ["-#{option.alias}"]
      else
        flags
      end
    end)
  end

  @doc """
  Gets all arguments from a Command module.

  Returns a list of DoIt.Argument structs.
  """
  def get_command_arguments(command_module) do
    if function_exported?(command_module, :__info__, 1) do
      case command_module.__info__(:attributes) do
        attributes when is_list(attributes) ->
          attributes
          |> Keyword.get_values(:arguments)
          |> List.flatten()

        _ ->
          []
      end
    else
      []
    end
  end

  @doc """
  Finds a command module by name from a MainCommand module.

  Returns the module atom or nil if not found.
  """
  def find_command_module(main_module, command_name) do
    case main_module.__info__(:attributes) do
      attributes when is_list(attributes) ->
        attributes
        |> Keyword.get_values(:commands)
        |> List.flatten()
        |> Enum.find(fn module ->
          {name, _} = module.command()
          name == command_name
        end)

      _ ->
        nil
    end
  end

  @doc """
  Finds a subcommand module by name from a Command module.

  Returns the module atom or nil if not found.
  """
  def find_subcommand_module(command_module, subcommand_name) do
    if function_exported?(command_module, :__info__, 1) do
      case command_module.__info__(:attributes) do
        attributes when is_list(attributes) ->
          attributes
          |> Keyword.get_values(:subcommands)
          |> List.flatten()
          |> Enum.find(fn module ->
            {name, _} = module.command()
            name == subcommand_name
          end)

        _ ->
          nil
      end
    else
      nil
    end
  end

  @doc """
  Resolves a command path to its final command module.

  Takes a main module and a list of command/subcommand names,
  returns the final command module or nil if path is invalid.

  ## Examples

      iex> resolve_command_path(MyApp, ["user", "create"])
      MyApp.User.Create
      
      iex> resolve_command_path(MyApp, ["invalid"])
      nil
  """
  def resolve_command_path(main_module, []) do
    main_module
  end

  def resolve_command_path(main_module, [command_name | rest]) do
    case find_command_module(main_module, command_name) do
      nil -> nil
      command_module -> resolve_subcommand_path(command_module, rest)
    end
  end

  defp resolve_subcommand_path(command_module, []) do
    command_module
  end

  defp resolve_subcommand_path(command_module, [subcommand_name | rest]) do
    case find_subcommand_module(command_module, subcommand_name) do
      nil -> nil
      subcommand_module -> resolve_subcommand_path(subcommand_module, rest)
    end
  end

  @doc """
  Gets the command structure as a nested map for introspection.

  Returns a map containing the full command hierarchy with metadata.
  """
  def get_command_structure(main_module) do
    {app_name, description} = main_module.command()

    commands =
      get_all_commands(main_module)
      |> Enum.map(fn command_name ->
        command_module = find_command_module(main_module, command_name)
        {_, command_description} = command_module.command()

        %{
          name: command_name,
          description: command_description,
          module: command_module,
          subcommands: get_subcommand_structure(command_module),
          options: get_command_options(command_module),
          arguments: get_command_arguments(command_module)
        }
      end)

    %{
      name: app_name,
      description: description,
      module: main_module,
      commands: commands
    }
  end

  defp get_subcommand_structure(command_module) do
    get_subcommands(command_module)
    |> Enum.map(fn subcommand_name ->
      subcommand_module = find_subcommand_module(command_module, subcommand_name)
      {_, subcommand_description} = subcommand_module.command()

      %{
        name: subcommand_name,
        description: subcommand_description,
        module: subcommand_module,
        subcommands: get_subcommand_structure(subcommand_module),
        options: get_command_options(subcommand_module),
        arguments: get_command_arguments(subcommand_module)
      }
    end)
  end

  @doc """
  Checks if a command has subcommands.
  """
  def has_subcommands?(command_module) do
    get_subcommands(command_module) != []
  end

  @doc """
  Gets all possible command paths as flat list.

  Returns a list of command paths where each path is a list of strings.
  """
  def get_all_command_paths(main_module) do
    get_command_structure(main_module).commands
    |> Enum.flat_map(&extract_command_paths(&1, []))
  end

  defp extract_command_paths(%{name: name, subcommands: []}, prefix) do
    [prefix ++ [name]]
  end

  defp extract_command_paths(%{name: name, subcommands: subcommands}, prefix) do
    current_path = [prefix ++ [name]]

    subcommand_paths =
      subcommands
      |> Enum.flat_map(&extract_command_paths(&1, prefix ++ [name]))

    current_path ++ subcommand_paths
  end
end
