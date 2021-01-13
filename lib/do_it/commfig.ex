defmodule DoIt.Commfig do
  use GenServer
  require Logger

  defmodule State do
    defstruct [:filename, :config]
  end

  def start_link(filename) do
    GenServer.start_link(__MODULE__, filename, name: __MODULE__)
  end

  def state() do
    GenServer.call(__MODULE__, :state)
  end

  def set(keys, value) when is_list(keys) do
    GenServer.cast(__MODULE__, {:set, keys, value})
  end

  def set(key, value) do
    GenServer.cast(__MODULE__, {:set, [key], value})
  end

  @impl true
  def init(filename) do
    config = case File.exists?(filename) do
      true ->
        filename
        |> File.read!()
        |> Jason.decode!()
      _ ->
        %{}
    end
    {:ok, %State{filename: filename, config: config}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:set, keys, value}, %State{filename: filename, config: config} = state) do
    with new_config <- put_in(config, keys, value) do
      Jason.encode!(new_config)
      |> Jason.Formatter.pretty_print()
      |> (&(File.write!(filename, &1))).()
      {:noreply, %{state | config: new_config}}
    end
  rescue
    ArgumentError ->
      {:noreply, state}
  end

end
