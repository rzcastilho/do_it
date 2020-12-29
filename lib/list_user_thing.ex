defmodule ListUserThing do
  @moduledoc false

  use DoIt.Command,
    description: "List user's 'thing' at GitHub",
    command: "list"

  param(:username, :string, "GitHub username")

  param(:thing, :string, "GitHub user's thing",
    allowed_values: ["repos", "following", "followers"]
  )

  flag(:filter, :string, "Filter output based on conditions provided", alias: :f, keep: true)

  flag(:format, :string, "Output format",
    allowed_values: ["table", "csv", "json"],
    default: "table"
  )

  flag(:limit, :integer, "Max number of search results", default: 5)

  flag(:verbose, :boolean, "Increase output information")

  def run(params, flags, context) do
    IO.inspect(params)
    IO.inspect(flags)
    IO.inspect(context)
    "get #{params[:username]}'s #{params[:thing]} from GitHub"
  end
end
