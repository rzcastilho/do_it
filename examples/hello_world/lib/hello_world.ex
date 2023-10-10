defmodule HelloWorld do
  use DoIt.MainCommand,
    description: "My useless CLI"

  command(HelloWorld.Say)
  command(HelloWorld.Template)
end
