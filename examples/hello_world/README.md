# HelloWorld CLI

A demonstration CLI application built with the [DoIt](https://hexdocs.pm/do_it/) library, showcasing command-line interface development in Elixir.

## Overview

HelloWorld CLI is a sample application that demonstrates the key features of the DoIt library:

- **Command Management**: Organized commands and subcommands
- **Template System**: Configurable message templates
- **Auto-completion**: Shell completion for commands and options
- **Help System**: Automatic help generation
- **Option Handling**: Support for flags, aliases, and validation

## Features

### Commands

- **`say`** - Display messages with customizable templates
- **`template`** - Manage message templates
  - **`set`** - Set a default template
  - **`unset`** - Remove the default template
  - **`show`** - Display the current template

### Built-in Commands

- **`help`** - Show help information
- **`version`** - Display version information
- **`completion`** - Shell auto-completion support

## Installation

### Building from Source

```bash
# Clone the repository (if not already done)
cd examples/hello_world

# Install dependencies
mix deps.get

# Build the executable
mix escript.build
```

This creates a `hello_world` executable in the current directory.

### Using Burrito (Cross-platform Binaries)

```bash
# Build release with Burrito
MIX_ENV=prod mix release

# Binaries will be available in burrito_out/
ls burrito_out/
```

## Usage

### Basic Commands

```bash
# Show help
./hello_world help

# Display version
./hello_world version

# Say hello with a template
./hello_world say "World" --template "Hello, <%= @message %>!"

# Set a default template
./hello_world template set "Greetings, <%= @message %>!"

# Use the default template
./hello_world say "Everyone"

# Show current template
./hello_world template show

# Remove default template
./hello_world template unset
```

### Command Options

#### `say` command

```bash
# Basic usage
./hello_world say "your message"

# With custom template
./hello_world say "World" --template "Hi <%= @message %>!"
./hello_world say "World" -t "Hi <%= @message %>!"

# Show help for say command
./hello_world say --help
```

#### `template` commands

```bash
# Set default template
./hello_world template set "Hello, <%= @message %>!"

# Show current template
./hello_world template show

# Remove template
./hello_world template unset

# Help for template commands
./hello_world template --help
./hello_world template set --help
```

## Shell Auto-completion

HelloWorld CLI includes comprehensive auto-completion support for bash, fish, and zsh.

### Installation

#### Bash

Add to your `~/.bashrc`:

```bash
eval "$(./hello_world completion bash)"
```

Or install system-wide:

```bash
./hello_world completion bash | sudo tee /etc/bash_completion.d/hello_world
```

#### Fish

```bash
./hello_world completion fish > ~/.config/fish/completions/hello_world.fish
```

#### Zsh

Add to your `~/.zshrc`:

```bash
eval "$(./hello_world completion zsh)"
```

### Testing Completion

After installation, you can test completion by typing:

```bash
./hello_world <TAB>          # Shows: say, template, help, version, completion
./hello_world template <TAB> # Shows: set, unset, show, --help
./hello_world say --<TAB>    # Shows: --help, --template
```

### Completion Commands

```bash
# Generate completion scripts
./hello_world completion bash
./hello_world completion fish
./hello_world completion zsh

# Show installation instructions
./hello_world completion install bash

# Debug completion structure
./hello_world completion debug

# Get help for completion
./hello_world completion help
```

## Examples

### Example 1: Basic Greeting

```bash
./hello_world say "World" --template "Hello, <%= @message %>!"
# Output: Hello, World!
```

### Example 2: Setting Default Template

```bash
# Set a default template
./hello_world template set "🎉 Welcome, <%= @message %>! 🎉"

# Use it without specifying template
./hello_world say "Alice"
# Output: 🎉 Welcome, Alice! 🎉

# Override with custom template
./hello_world say "Bob" --template "Hi <%= @message %>!"
# Output: Hi Bob!
```

### Example 3: Template Management

```bash
# Check current template
./hello_world template show
# Output: Current template: 🎉 Welcome, <%= @message %>! 🎉

# Remove template
./hello_world template unset
# Output: Default template removed

# Try to use without template
./hello_world say "Charlie"
# Output: Pass a template parameter or define a default template using template set command
```

## Development

### Project Structure

```
lib/
├── hello_world.ex              # Main command module
├── hello_world/
│   ├── say.ex                  # Say command implementation
│   └── template/
│       ├── template.ex         # Template command with subcommands
│       ├── set.ex             # Set template subcommand
│       ├── unset.ex           # Unset template subcommand
│       └── show.ex            # Show template subcommand
```

### Running Tests

```bash
mix test
```

### Code Analysis

```bash
# Run Credo for code analysis
mix credo

# Format code
mix format
```

### Using as Development Template

This example serves as a template for building CLI applications with DoIt:

1. **Study the command structure** in `lib/hello_world/`
2. **Examine option and argument definitions** in each command
3. **Review the template system** implementation
4. **Understand subcommand organization** in the template module

## Configuration

HelloWorld CLI stores configuration in a local file managed by the DoIt library. Templates are persisted between runs.

### Configuration Location

The configuration is stored using DoIt's built-in configuration management:

- **Development**: Local to the project directory
- **Production**: User-specific configuration directory

## Dependencies

- **DoIt**: CLI framework (`{:do_it, path: "../../"}`)
- **Elixir**: 1.14 or later
- **Erlang/OTP**: Compatible version

## License

This example is part of the DoIt library and is released under the Apache License 2.0.

## Contributing

This is an example project demonstrating DoIt library features. For contributing to the DoIt library itself, see the main project repository.

## Learn More

- [DoIt Library Documentation](https://hexdocs.pm/do_it/)
- [DoIt GitHub Repository](https://github.com/rzcastilho/do_it)
- [Elixir Documentation](https://elixir-lang.org/docs.html)