defmodule IntrospectionTest.User.Create do
  use DoIt.Command,
    description: "Create a new user"

  argument(:username, :string, "Username for the new user")
  argument(:email, :string, "Email address")
  option(:admin, :boolean, "Make user admin", alias: :a)
  option(:role, :string, "User role", allowed_values: ["user", "admin", "moderator"])

  def run(_args, _opts, _context), do: :ok
end

defmodule IntrospectionTest.User.Delete do
  use DoIt.Command,
    description: "Delete a user"

  argument(:username, :string, "Username to delete")
  option(:force, :boolean, "Force deletion", alias: :f)

  def run(_args, _opts, _context), do: :ok
end

defmodule IntrospectionTest.User.List do
  use DoIt.Command,
    description: "List all users"

  option(:format, :string, "Output format", allowed_values: ["table", "json"])
  option(:limit, :integer, "Maximum number of users to show")

  def run(_args, _opts, _context), do: :ok
end

defmodule IntrospectionTest.Config.Get do
  use DoIt.Command,
    description: "Get configuration value"

  argument(:key, :string, "Configuration key")
  option(:default, :string, "Default value if key not found")

  def run(_args, _opts, _context), do: :ok
end

defmodule IntrospectionTest.Config.Set do
  use DoIt.Command,
    description: "Set configuration value"

  argument(:key, :string, "Configuration key")
  argument(:value, :string, "Configuration value")

  def run(_args, _opts, _context), do: :ok
end

defmodule IntrospectionTest.SimpleCommand do
  use DoIt.Command,
    description: "A simple command with no subcommands"

  argument(:input, :string, "Input data")
  option(:verbose, :boolean, "Verbose output", alias: :v)
  option(:output, :string, "Output file")

  def run(_args, _opts, _context), do: :ok
end

# Intermediate command modules (depend on leaf modules)
defmodule IntrospectionTest.User do
  use DoIt.Command,
    description: "User management commands"

  subcommand(IntrospectionTest.User.Create)
  subcommand(IntrospectionTest.User.Delete)
  subcommand(IntrospectionTest.User.List)
end

defmodule IntrospectionTest.Config do
  use DoIt.Command,
    description: "Configuration management"

  subcommand(IntrospectionTest.Config.Get)
  subcommand(IntrospectionTest.Config.Set)
end

# Main command module (depends on intermediate modules)
defmodule IntrospectionTest.MainApp do
  use DoIt.MainCommand,
    description: "Test CLI Application"

  command(IntrospectionTest.User)
  command(IntrospectionTest.Config)
  command(IntrospectionTest.SimpleCommand)
end

defmodule DoIt.IntrospectionTest do
  use ExUnit.Case, async: true
  alias DoIt.Introspection

  describe "get_all_commands/1" do
    test "returns all top-level commands" do
      commands = Introspection.get_all_commands(IntrospectionTest.MainApp)

      assert length(commands) == 3
      assert "user" in commands
      assert "config" in commands
      assert "simple_command" in commands
    end

    test "returns empty list for non-existent module" do
      defmodule EmptyMainApp do
        use DoIt.MainCommand, description: "Empty app"
      end

      commands = Introspection.get_all_commands(EmptyMainApp)
      assert commands == []
    end
  end

  describe "get_subcommands/1" do
    test "returns subcommands for command with subcommands" do
      subcommands = Introspection.get_subcommands(IntrospectionTest.User)

      assert length(subcommands) == 3
      assert "create" in subcommands
      assert "delete" in subcommands
      assert "list" in subcommands
    end

    test "returns empty list for command without subcommands" do
      subcommands = Introspection.get_subcommands(IntrospectionTest.SimpleCommand)
      assert subcommands == []
    end

    test "returns empty list for non-existent module" do
      subcommands = Introspection.get_subcommands(NonExistentModule)
      assert subcommands == []
    end
  end

  describe "get_command_options/1" do
    test "returns all options for a command" do
      options = Introspection.get_command_options(IntrospectionTest.User.Create)

      assert length(options) == 3  # help + admin + role
      option_names = Enum.map(options, & &1.name)
      assert :help in option_names
      assert :admin in option_names
      assert :role in option_names
    end

    test "returns help option for command with no custom options" do
      options = Introspection.get_command_options(IntrospectionTest.User)

      assert length(options) == 1
      assert List.first(options).name == :help
    end

    test "returns empty list for non-existent module" do
      options = Introspection.get_command_options(NonExistentModule)
      assert options == []
    end
  end

  describe "get_command_option_flags/1" do
    test "returns option flags including aliases" do
      flags = Introspection.get_command_option_flags(IntrospectionTest.User.Create)

      assert "--help" in flags
      assert "--admin" in flags
      assert "-a" in flags
      assert "--role" in flags
    end

    test "returns only long flags when no aliases" do
      flags = Introspection.get_command_option_flags(IntrospectionTest.Config.Get)

      assert "--help" in flags
      assert "--default" in flags
      refute "-d" in flags  # no alias defined
    end
  end

  describe "get_command_arguments/1" do
    test "returns arguments for command with arguments" do
      arguments = Introspection.get_command_arguments(IntrospectionTest.User.Create)

      assert length(arguments) == 2
      arg_names = Enum.map(arguments, & &1.name)
      assert :username in arg_names
      assert :email in arg_names
    end

    test "returns empty list for command without arguments" do
      arguments = Introspection.get_command_arguments(IntrospectionTest.User.List)
      assert arguments == []
    end

    test "returns empty list for non-existent module" do
      arguments = Introspection.get_command_arguments(NonExistentModule)
      assert arguments == []
    end
  end

  describe "find_command_module/2" do
    test "finds existing command module" do
      module = Introspection.find_command_module(IntrospectionTest.MainApp, "user")
      assert module == IntrospectionTest.User

      module = Introspection.find_command_module(IntrospectionTest.MainApp, "config")
      assert module == IntrospectionTest.Config

      module = Introspection.find_command_module(IntrospectionTest.MainApp, "simple_command")
      assert module == IntrospectionTest.SimpleCommand
    end

    test "returns nil for non-existent command" do
      module = Introspection.find_command_module(IntrospectionTest.MainApp, "nonexistent")
      assert module == nil
    end
  end

  describe "find_subcommand_module/2" do
    test "finds existing subcommand module" do
      module = Introspection.find_subcommand_module(IntrospectionTest.User, "create")
      assert module == IntrospectionTest.User.Create

      module = Introspection.find_subcommand_module(IntrospectionTest.User, "delete")
      assert module == IntrospectionTest.User.Delete

      module = Introspection.find_subcommand_module(IntrospectionTest.Config, "get")
      assert module == IntrospectionTest.Config.Get
    end

    test "returns nil for non-existent subcommand" do
      module = Introspection.find_subcommand_module(IntrospectionTest.User, "nonexistent")
      assert module == nil
    end

    test "returns nil for command without subcommands" do
      module = Introspection.find_subcommand_module(IntrospectionTest.SimpleCommand, "anything")
      assert module == nil
    end

    test "returns nil for non-existent module" do
      module = Introspection.find_subcommand_module(NonExistentModule, "anything")
      assert module == nil
    end
  end

  describe "resolve_command_path/2" do
    test "resolves empty path to main module" do
      module = Introspection.resolve_command_path(IntrospectionTest.MainApp, [])
      assert module == IntrospectionTest.MainApp
    end

    test "resolves single command path" do
      module = Introspection.resolve_command_path(IntrospectionTest.MainApp, ["user"])
      assert module == IntrospectionTest.User

      module = Introspection.resolve_command_path(IntrospectionTest.MainApp, ["simple_command"])
      assert module == IntrospectionTest.SimpleCommand
    end

    test "resolves nested command path" do
      module = Introspection.resolve_command_path(IntrospectionTest.MainApp, ["user", "create"])
      assert module == IntrospectionTest.User.Create

      module = Introspection.resolve_command_path(IntrospectionTest.MainApp, ["config", "set"])
      assert module == IntrospectionTest.Config.Set
    end

    test "returns nil for invalid command path" do
      module = Introspection.resolve_command_path(IntrospectionTest.MainApp, ["nonexistent"])
      assert module == nil

      module = Introspection.resolve_command_path(IntrospectionTest.MainApp, ["user", "nonexistent"])
      assert module == nil

      module = Introspection.resolve_command_path(IntrospectionTest.MainApp, ["simple_command", "invalid"])
      assert module == nil
    end
  end

  describe "get_command_structure/1" do
    test "returns complete command structure" do
      structure = Introspection.get_command_structure(IntrospectionTest.MainApp)

      assert structure.name == ""  # No application name in test environment
      assert structure.description == "Test CLI Application"
      assert structure.module == IntrospectionTest.MainApp
      assert length(structure.commands) == 3

      # Find user command
      user_command = Enum.find(structure.commands, &(&1.name == "user"))
      assert user_command.description == "User management commands"
      assert user_command.module == IntrospectionTest.User
      assert length(user_command.subcommands) == 3

      # Find create subcommand
      create_subcommand = Enum.find(user_command.subcommands, &(&1.name == "create"))
      assert create_subcommand.description == "Create a new user"
      assert create_subcommand.module == IntrospectionTest.User.Create
      assert length(create_subcommand.arguments) == 2
      assert length(create_subcommand.options) == 3
      assert create_subcommand.subcommands == []

      # Find simple command
      simple_command = Enum.find(structure.commands, &(&1.name == "simple_command"))
      assert simple_command.description == "A simple command with no subcommands"
      assert simple_command.subcommands == []
      assert length(simple_command.arguments) == 1
      assert length(simple_command.options) == 3  # help + verbose + output
    end
  end

  describe "has_subcommands?/1" do
    test "returns true for command with subcommands" do
      assert Introspection.has_subcommands?(IntrospectionTest.User) == true
      assert Introspection.has_subcommands?(IntrospectionTest.Config) == true
    end

    test "returns false for command without subcommands" do
      assert Introspection.has_subcommands?(IntrospectionTest.SimpleCommand) == false
      assert Introspection.has_subcommands?(IntrospectionTest.User.Create) == false
    end
  end

  describe "get_all_command_paths/1" do
    test "returns all possible command paths" do
      paths = Introspection.get_all_command_paths(IntrospectionTest.MainApp)

      # Should include all commands and their subcommands
      expected_paths = [
        ["user"],
        ["user", "create"],
        ["user", "delete"],
        ["user", "list"],
        ["config"],
        ["config", "get"],
        ["config", "set"],
        ["simple_command"]
      ]

      assert length(paths) == length(expected_paths)

      for expected_path <- expected_paths do
        assert expected_path in paths
      end
    end
  end

  describe "edge cases and error handling" do
    test "handles module without DoIt command structure" do
      defmodule NonDoItModule do
        def some_function, do: :ok
      end

      assert Introspection.get_all_commands(NonDoItModule) == []
      assert Introspection.get_subcommands(NonDoItModule) == []
      assert Introspection.get_command_options(NonDoItModule) == []
      assert Introspection.get_command_arguments(NonDoItModule) == []
    end

    test "handles nil and invalid inputs gracefully" do
      # These should not crash, but return empty results
      assert Introspection.find_command_module(IntrospectionTest.MainApp, nil) == nil
      assert Introspection.find_subcommand_module(IntrospectionTest.User, nil) == nil
    end
  end

  describe "option details" do
    test "preserves option metadata" do
      options = Introspection.get_command_options(IntrospectionTest.User.Create)

      role_option = Enum.find(options, &(&1.name == :role))
      assert role_option.type == :string
      assert role_option.description == "User role"
      assert role_option.allowed_values == ["user", "admin", "moderator"]

      admin_option = Enum.find(options, &(&1.name == :admin))
      assert admin_option.type == :boolean
      assert admin_option.alias == :a
    end
  end

  describe "argument details" do
    test "preserves argument metadata" do
      arguments = Introspection.get_command_arguments(IntrospectionTest.User.Create)

      username_arg = Enum.find(arguments, &(&1.name == :username))
      assert username_arg.type == :string
      assert username_arg.description == "Username for the new user"

      email_arg = Enum.find(arguments, &(&1.name == :email))
      assert email_arg.type == :string
      assert email_arg.description == "Email address"
    end
  end
end
