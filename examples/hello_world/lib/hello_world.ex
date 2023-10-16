defmodule HelloWorld do
  use DoIt.MainCommand,
    description: "HelloWorld CLI"

  command(HelloWorld.Say)
  command(HelloWorld.Template)
end
