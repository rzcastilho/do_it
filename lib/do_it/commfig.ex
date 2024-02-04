defmodule DoIt.Commfig do
  @moduledoc false
  use GenServer
  require Logger

  @default_app_name Mix.Project.config()[:app]
                    |> Atom.to_string()

  defmodule State do
    @moduledoc false
    defstruct [:dir, :file, :data]
  end

  def start_link([dirname, filename]) when is_nil(dirname) or is_nil(filename),
    do: start_link([System.tmp_dir(), @default_app_name])

  def start_link([dirname, filename]) do
    GenServer.start_link(__MODULE__, [dirname, filename], name: __MODULE__)
  end

  def start_link(_),
    do:
      raise(
        DoIt.InitConfigError,
        message:
          "dirname and filename are required for the initialization of the persistent configuration"
      )

  def start_link(),
    do:
      raise(
        DoIt.InitConfigError,
        message:
          "dirname and filename are required for the initialization of the persistent configuration"
      )

  def get_dir() do
    GenServer.call(__MODULE__, :get_dir)
  end

  def get_file() do
    GenServer.call(__MODULE__, :get_file)
  end

  def get_data() do
    GenServer.call(__MODULE__, :get_data)
  end

  def set(keys, value) when is_list(keys) do
    GenServer.call(__MODULE__, {:set, keys, value})
  end

  def set(key, value) do
    GenServer.call(__MODULE__, {:set, [key], value})
  end

  def unset(keys) when is_list(keys) do
    GenServer.call(__MODULE__, {:unset, keys})
  end

  def unset(key) do
    GenServer.call(__MODULE__, {:unset, [key]})
  end

  def get(keys) when is_list(keys) do
    GenServer.call(__MODULE__, {:get, keys})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, [key]})
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

    {:ok, %State{dir: dirname, file: file, data: data}}
  end

  @impl true
  def handle_call(:get_dir, _from, %State{dir: dir} = state) do
    {:reply, dir, state}
  end

  @impl true
  def handle_call(:get_file, _from, %State{file: file} = state) do
    {:reply, file, state}
  end

  @impl true
  def handle_call(:get_data, _from, %State{data: data} = state) do
    {:reply, data, state}
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

  @impl true
  def handle_call({:unset, keys}, _from, %State{file: file, data: data} = state) do
    with {_, new_data} <- pop_in(data, keys) do
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

  @impl true
  def handle_call({:get, keys}, _from, %State{data: data} = state) do
    {:reply, get_in(data, keys), state}
  end
end
