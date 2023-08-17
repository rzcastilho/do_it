defmodule HelloWorld.Template do
  use DoIt.Command,
    description: "Manage HelloWorld Template",
    sub_commands: [
      HelloWorld.Template.Set,
      HelloWorld.Template.Unset,
      HelloWorld.Template.Default
    ]

  def next(%{}, %{}) do
    %{}
  end
end
