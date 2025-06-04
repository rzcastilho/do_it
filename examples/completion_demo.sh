#!/bin/bash

# DoIt Auto-completion Demo Script
# This script demonstrates the auto-completion features of the DoIt library

echo "=== DoIt Auto-completion Demo ==="
echo

# Build the hello_world example
echo "Building hello_world example..."
cd examples/hello_world

if ! mix escript.build > /dev/null 2>&1; then
    echo "✗ Failed to build hello_world CLI"
    exit 1
fi

echo "✓ Built hello_world CLI"
echo

# Show available completion commands
echo "1. Available completion commands:"
echo "   ./hello_world completion help"
./hello_world completion help
echo

# Generate completion scripts
echo "2. Generate bash completion script:"
echo "   ./hello_world completion bash"
echo "   (showing first 10 lines)"
./hello_world completion bash | head -10
echo "   ..."
echo

# Show top-level command completions
echo "3. Top-level command completions:"
echo "   ./hello_world completion complete"
./hello_world completion complete
echo

# Show subcommand completions
echo "4. Template subcommand completions:"
echo "   ./hello_world completion complete template"
./hello_world completion complete template
echo

# Show option completions
echo "5. Say command option completions:"
echo "   ./hello_world completion complete say"
./hello_world completion complete say
echo

# Show partial command matching
echo "6. Partial command matching:"
echo "   ./hello_world completion complete te"
./hello_world completion complete te
echo

# Show installation instructions
echo "7. Installation instructions for bash:"
echo "   ./hello_world completion install bash"
./hello_world completion install bash
echo

# Show debug information
echo "8. Debug completion structure:"
echo "   ./hello_world completion debug"
echo "   (showing summary)"
./hello_world completion debug | head -20
echo "   ..."
echo

echo "=== Demo Complete ==="
echo
echo "To test completion interactively:"
echo "1. Generate completion script: ./hello_world completion bash > /tmp/hello_world_completion"
echo "2. Source it in your shell: source /tmp/hello_world_completion"
echo "3. Try typing: ./hello_world <TAB> or ./hello_world template <TAB>"
