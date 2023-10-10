defmodule HelloWorld.Template do
  use DoIt.Command,
    description: "Manage HelloWorld Template"

  subcommand(HelloWorld.Template.Set)
  subcommand(HelloWorld.Template.Unset)
  subcommand(HelloWorld.Template.Show)
end
