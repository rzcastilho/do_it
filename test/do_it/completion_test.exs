defmodule DoIt.CompletionTest do
  use ExUnit.Case
  alias DoIt.Completion

  describe "parse_completion_context/1" do
    test "parses empty args as command completion" do
      context = Completion.parse_completion_context([])
      assert context == {:command, []}
    end

    test "parses single command" do
      context = Completion.parse_completion_context(["say"])
      assert context == {:command, ["say"]}
    end

    test "parses command with subcommand" do
      context = Completion.parse_completion_context(["config", "set"])
      assert context == {:command, ["config", "set"]}
    end

    test "parses option waiting for value" do
      context = Completion.parse_completion_context(["say", "--format"])
      assert context == {:option_value, "format", ["say"]}
    end

    test "parses short option waiting for value" do
      context = Completion.parse_completion_context(["say", "-f"])
      assert context == {:option_value, "f", ["say"]}
    end

    test "parses option with equals value" do
      context = Completion.parse_completion_context(["say", "--format=json"])
      assert context == {:command, ["say"]}
    end

    test "handles mixed commands and options" do
      context = Completion.parse_completion_context(["config", "set", "--verbose"])
      assert context == {:option_value, "verbose", ["config", "set"]}
    end
  end

  describe "Shell script generation" do
    test "generate_bash_completion/2 generates valid bash script" do
      script = Completion.generate_bash_completion(nil, "test_cli")
      assert String.contains?(script, "#!/bin/bash")
      assert String.contains?(script, "_test_cli_completions")
      assert String.contains?(script, "complete -F _test_cli_completions test_cli")
      assert String.contains?(script, "test_cli completion complete")
    end

    test "generate_fish_completion/2 generates valid fish script" do
      script = Completion.generate_fish_completion(nil, "test_cli")
      assert String.contains?(script, "function __test_cli_complete")
      assert String.contains?(script, "complete -c test_cli")
      assert String.contains?(script, "test_cli completion complete")
    end

    test "generate_zsh_completion/2 generates valid zsh script" do
      script = Completion.generate_zsh_completion(nil, "test_cli")
      assert String.contains?(script, "#compdef test_cli")
      assert String.contains?(script, "_test_cli()")
      assert String.contains?(script, "test_cli completion complete")
    end
  end

  describe "Installation instructions" do
    test "get_installation_instructions/2 returns bash instructions" do
      instructions = Completion.get_installation_instructions("test_cli", "bash")
      assert String.contains?(instructions, "eval \"$(test_cli completion bash)\"")
      assert String.contains?(instructions, "~/.bashrc")
    end

    test "get_installation_instructions/2 returns fish instructions" do
      instructions = Completion.get_installation_instructions("test_cli", "fish")
      assert String.contains?(instructions, "test_cli completion fish >")
      assert String.contains?(instructions, "~/.config/fish/completions/test_cli.fish")
    end

    test "get_installation_instructions/2 returns zsh instructions" do
      instructions = Completion.get_installation_instructions("test_cli", "zsh")
      assert String.contains?(instructions, "eval \"$(test_cli completion zsh)\"")
      assert String.contains?(instructions, "~/.zshrc")
    end

    test "get_installation_instructions/2 handles unsupported shell" do
      instructions = Completion.get_installation_instructions("test_cli", "unsupported")
      assert String.contains?(instructions, "Unsupported shell")
    end
  end

  describe "complete_option_value/3" do
    test "returns empty list for invalid command path" do
      # Use a simple module reference that won't cause issues
      completions = Completion.complete_option_value(DoIt.CompletionTest, "format", ["nonexistent"])
      assert completions == []
    end
  end
end