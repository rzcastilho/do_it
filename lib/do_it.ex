defmodule DoIt do
  use DoIt.Action

  action :hello, "Say hello" do
    flag :message, :string, alias: :m
  end

  def run(args) do
    IO.inspect @options
    parsedOptions = OptionParser.parse(args, @options)
    IO.inspect parsedOptions
    true
  end

end
