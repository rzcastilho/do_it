defmodule DoIt.Commfig do
  use GenServer
  require Logger

  defmodule State do
    defstruct [:file, :data]
  end

  def start_link([dirname, filename]) do
    GenServer.start_link(__MODULE__, [dirname, filename], name: __MODULE__)
  end

  def get_data() do
    GenServer.call(__MODULE__, :get_data)
  end

  def get_file() do
    GenServer.call(__MODULE__, :get_file)
  end

  def set(keys, value) when is_list(keys) do
    GenServer.call(__MODULE__, {:set, keys, value})
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, [key], value})
  end

  @impl true
  def init([dirname, filename]) do
    Process.flag(:trap_exit, true)
    if !File.exists?(dirname), do: File.mkdir_p(dirname)
    file = Path.join(dirname, filename)

    data =
      case File.exists?(file) do
        true ->
          file
          |> File.read!()
          |> Jason.decode!()

        _ ->
          %{}
      end

    {:ok, %State{file: file, data: data}}
  end

  @impl true
  def handle_call(:get_data, _from, %State{data: data} = state) do
    {:reply, data, state}
  end

  @impl true
  def handle_call(:get_file, _from, %State{file: file} = state) do
    {:reply, file, state}
  end

  @impl true
  def handle_call({:set, keys, value}, _from, %State{file: file, data: data} = state) do
    with new_data <- put_in(data, keys, value) do
      Jason.encode!(new_data)
      |> Jason.Formatter.pretty_print()
      |> (&File.write!(file, &1)).()

      {:reply, :ok, %{state | data: new_data}}
    end
  rescue
    e in ArgumentError ->
      {:reply, {:error, ArgumentError.message(e)}, state}

    e in FunctionClauseError ->
      {:reply, {:error, FunctionClauseError.message(e)}, state}
  end
end
