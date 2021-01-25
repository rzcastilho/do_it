defmodule DoIt do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {
        DoIt.Commfig,
        [
          Application.get_env(:do_it, DoIt.Commfig)[:dirname],
          Application.get_env(:do_it, DoIt.Commfig)[:filename]
        ]
      }
    ]

    opts = [strategy: :one_for_one, name: DoIt.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
