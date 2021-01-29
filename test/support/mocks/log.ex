defmodule LogMock do
  use GenServer

  defstruct [:pid]
  alias __MODULE__, as: State

  alias TeslaMate.Log.{Drive, ChargingProcess, Update, Car, Position}
  alias TeslaMate.Log

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  def start_state(name, car, state), do: GenServer.call(name, {:start_state, car, state})
  def get_current_state(name, car), do: GenServer.call(name, {:get_current_state, car})

  def start_drive(name, car), do: GenServer.call(name, {:start_drive, car})
  def close_drive(name, drive), do: GenServer.call(name, {:close_drive, drive})

  def start_update(name, car), do: GenServer.call(name, {:start_update, car})
  def cancel_update(name, update), do: GenServer.call(name, {:cancel_update, update})

  def finish_update(name, update, version),
    do: GenServer.call(name, {:finish_update, update, version})

  def start_charging_process(name, car, position_attrs, opts \\ []) do
    GenServer.call(name, {:start_charging_process, car, position_attrs, opts})
  end

  def complete_charging_process(name, cproc, opts \\ []) do
    GenServer.call(name, {:complete_charging_process, cproc, opts})
  end

  def insert_position(name, car_or_drive, attrs) do
    GenServer.call(name, {:insert_position, car_or_drive, attrs})
  end

  def insert_charge(name, cproc, attrs) do
    GenServer.call(name, {:insert_charge, cproc, attrs})
  end

  def get_positions_without_elevation(name, min_id, opts) do
    GenServer.call(name, {:get_positions_without_elevation, min_id, opts})
  end

  def update_car(name, car, attrs) do
    GenServer.call(name, {:update_car, car, attrs})
  end

  def get_latest_position(name, car) do
    GenServer.call(name, {:get_latest_position, car})
  end

  # Callbacks

  @impl true
  def init(opts) do
    {:ok, %State{pid: Keyword.fetch!(opts, :pid)}}
  end

  @impl true
  def handle_call({:start_state, _car, s} = action, _from, %State{pid: pid} = state) do
    send(pid, action)
    {:reply, {:ok, %Log.State{state: s, start_date: DateTime.utc_now()}}, state}
  end

  def handle_call({:get_current_state, _}, _from, state) do
    {:reply, {:ok, %Log.State{state: :online, start_date: DateTime.from_unix!(0)}}, state}
  end

  def handle_call({:insert_position, _, _attrs} = action, _from, %State{pid: pid} = state) do
    send(pid, action)
    {:reply, {:ok, %Log.Position{id: 111}}, state}
  end

  def handle_call({:start_charging_process, _, _, _} = action, _from, %State{pid: pid} = state) do
    send(pid, action)
    {:reply, {:ok, %ChargingProcess{id: 99, start_date: DateTime.utc_now()}}, state}
  end

  def handle_call({:complete_charging_process, cproc, _} = action, _from, %State{} = state) do
    send(state.pid, action)
    new_cproc = %ChargingProcess{cproc | charge_energy_added: 45, end_date: DateTime.utc_now()}
    {:reply, {:ok, new_cproc}, state}
  end

  def handle_call({:start_drive, _car} = action, _from, %State{pid: pid} = state) do
    send(pid, action)
    {:reply, {:ok, %Drive{id: 111}}, state}
  end

  def handle_call({:close_drive, _drive} = action, _from, %State{pid: pid} = state) do
    send(pid, action)
    {:reply, {:ok, %Drive{duration_min: 10, distance: 20.0}}, state}
  end

  def handle_call({:start_update, _car} = action, _from, %State{pid: pid} = state) do
    send(pid, action)
    {:reply, {:ok, %Update{id: 111}}, state}
  end

  def handle_call({:cancel_update, _update} = action, _from, %State{pid: pid} = state) do
    send(pid, action)
    {:reply, {:ok, %Update{}}, state}
  end

  def handle_call({:finish_update, _update, _version} = action, _from, %State{pid: pid} = state) do
    send(pid, action)
    {:reply, {:ok, %Update{}}, state}
  end

  def handle_call({:get_positions_without_elevation, min_id, _opts}, _from, state) do
    send(state.pid, {:get_positions_without_elevation, min_id})
    {:reply, {[], nil}, state}
  end

  def handle_call({:update_car, car, attrs} = _action, _from, %State{pid: _pid} = state) do
    result =
      car
      |> Car.changeset(attrs)
      |> Ecto.Changeset.apply_changes()

    {:reply, {:ok, result}, state}
  end

  def handle_call({:get_latest_position, _car}, _from, state) do
    {:reply, %Position{latitude: 0.0, longitude: 0.0}, state}
  end

  def handle_call(action, _from, %State{pid: pid} = state) do
    send(pid, action)
    {:reply, :ok, state}
  end
end
