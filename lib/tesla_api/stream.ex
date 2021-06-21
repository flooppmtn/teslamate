defmodule TeslaApi.Stream do
  use WebSockex

  require Logger
  alias TeslaApi.Auth
  alias __MODULE__.Data

  defmodule State do
    defstruct auth: nil,
              vehicle_id: nil,
              timer: nil,
              receiver: &IO.inspect/1,
              last_data: nil,
              timeouts: 0,
              disconnects: 0
  end

  @endpoint_url "wss://streaming.vn.teslamotors.com/streaming/"

  @columns ~w(speed odometer soc elevation est_heading est_lat est_lng power shift_state range
              est_range heading)a

  @cacerts CAStore.file_path()
           |> File.read!()
           |> :public_key.pem_decode()
           |> Enum.map(fn {_, cert, _} -> cert end)

  def start_link(args) do
    state = %State{
      receiver: Keyword.get(args, :receiver, &Logger.debug(inspect(&1))),
      vehicle_id: Keyword.fetch!(args, :vehicle_id),
      auth: Keyword.fetch!(args, :auth)
    }

    WebSockex.start_link(@endpoint_url, __MODULE__, state,
      socket_recv_timeout: :timer.seconds(10),
      cacerts: @cacerts,
      insecure: false,
      async: true
    )
  end

  def disconnect(pid) do
    WebSockex.cast(pid, :disconnect)
  end

  @impl true
  def handle_cast(:disconnect, %State{vehicle_id: vid} = state) do
    send(self(), :exit)
    {:reply, frame!(%{msg_type: "data:unsubscribe", tag: "#{vid}"}), state}
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.debug("WebSocket connection established")
    send(self(), :subscribe)
    {:ok, state}
  end

  @impl true
  def handle_info(:subscribe, %State{auth: %Auth{token: token}, vehicle_id: vid} = state) do
    Logger.debug("Subscribing …")

    cancel_timer(state.timer)
    ms = exp_backoff_ms(state.timeouts, min_seconds: 10, max_seconds: 30)
    timer = Process.send_after(self(), :timeout, ms)

    connect_message = %{
      msg_type: "data:subscribe_oauth",
      token: token,
      value: Enum.join(@columns, ","),
      tag: "#{vid}"
    }

    {:reply, frame!(connect_message), %State{state | timer: timer}}
  end

  def handle_info(:timeout, %State{receiver: receiver} = state) do
    Logger.info("Streaming Timeout!")

    if match?(%State{last_data: %Data{}}, state) and rem(state.timeouts, 10) == 4 do
      receiver.(:inactive)
    end

    {:close, %State{state | timeouts: state.timeouts + 1}}
  end

  def handle_info(:exit, _state) do
    exit(:normal)
  end

  @impl true
  def handle_frame({_type, msg}, %State{vehicle_id: vid} = state) do
    tag = to_string(vid)

    cancel_timer(state.timer)
    timer = Process.send_after(self(), :timeout, :timer.seconds(30))
    state = %State{state | timer: timer}

    case Jason.decode(msg) do
      {:ok, %{"msg_type" => "control:hello", "connection_timeout" => t}} ->
        Logger.debug("control:hello – #{t}")
        {:ok, state}

      {:ok, %{"msg_type" => "data:update", "tag" => ^tag, "value" => data}}
      when is_binary(data) ->
        data =
          Enum.zip([:time | @columns], String.split(data, ","))
          |> Enum.into(%{})
          |> Data.into!()

        state.receiver.(data)

        {:ok, %State{state | last_data: data, timeouts: 0, disconnects: 0}}

      {:ok, %{"msg_type" => "data:error", "tag" => ^tag, "error_type" => "vehicle_disconnected"}} ->
        Logger.debug("Vehicle disconnected")

        ms =
          case state do
            %State{last_data: %Data{shift_state: s}} when s in ~w(P D N R) ->
              exp_backoff_ms(state.disconnects, base: 1.3, max_seconds: 8)

            %State{} ->
              :timer.seconds(15)
          end

        Process.send_after(self(), :subscribe, ms)

        {:ok, %State{state | disconnects: state.disconnects + 1}}

      {:ok, %{"msg_type" => "data:error", "tag" => ^tag, "error_type" => "client_error"} = msg} ->
        raise "Client Error: #{inspect(msg)}"

      {:ok, %{"msg_type" => "data:error", "tag" => ^tag} = msg} ->
        Logger.error("Error: #{inspect(msg)}")
        {:ok, state}

      {:ok, msg} ->
        Logger.warn("Unkown Message: #{inspect(msg, pretty: true)}")
        {:ok, state}

      {:error, reason} ->
        Logger.error("Invalid JSON: #{inspect(reason)}")
        {:ok, state}
    end
  end

  @impl true
  def handle_disconnect(%{reason: {:remote, :closed}}, state) do
    Logger.warn("WebSocket disconnected. Reconnecting …")
    {:reconnect, %State{state | last_data: nil}}
  end

  def handle_disconnect(%{reason: {:local, :normal}}, state) do
    Logger.debug("Reconnecting …")
    {:reconnect, state}
  end

  def handle_disconnect(status, state) do
    Logger.warn("Disconnected! #{inspect(status)}}")
    {:ok, state}
  end

  @impl true
  def terminate({exception, stacktrace}, _state) do
    # https://github.com/Azolo/websockex/issues/51
    if Exception.exception?(exception) do
      Logger.error(fn -> Exception.format(:error, exception, stacktrace) end)
    end

    :ok
  end

  def terminate(_, _), do: :ok

  ## Private

  defp frame!(data) when is_map(data), do: {:text, Jason.encode!(data)}

  defp exp_backoff_ms(n, opts) when is_number(n) and 0 <= n do
    base = Keyword.get(opts, :base, 2)
    max = Keyword.get(opts, :max_seconds, 30)
    min = Keyword.get(opts, :min_seconds, 0)

    :math.pow(base, n) |> min(max) |> max(min) |> round() |> :timer.seconds()
  end

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(ref) when is_reference(ref), do: Process.cancel_timer(ref)
end
