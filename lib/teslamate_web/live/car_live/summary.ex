defmodule TeslaMateWeb.CarLive.Summary do
  use Phoenix.LiveView

  import TeslaMateWeb.Gettext

  alias TeslaMateWeb.CarView
  alias TeslaMate.Vehicles
  alias TeslaMate.Log.Car

  @impl true
  def mount(%{car: %Car{} = car, settings: settings}, socket) do
    if connected?(socket) do
      send(self(), :update_duration)
      Vehicles.subscribe(car.id)
    end

    summary = Vehicles.summary(car.id)

    assigns = %{
      car: car,
      summary: summary,
      settings: settings,
      translate_state: &translate_state/1,
      duration: duration_str(summary.since),
      error: nil,
      error_timeout: nil
    }

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    CarView.render("summary.html", assigns)
  end

  @impl true
  def handle_event("suspend_logging", _val, socket) do
    cancel_timer(socket.assigns.error_timeout)

    assigns =
      case Vehicles.suspend_logging(socket.assigns.car.id) do
        :ok ->
          %{error: nil, error_timeout: nil}

        {:error, reason} ->
          %{
            error: translate_error(reason),
            error_timeout: Process.send_after(self(), :hide_error, 5_000)
          }
      end

    {:noreply, assign(socket, assigns)}
  end

  def handle_event("resume_logging", _val, socket) do
    :ok = Vehicles.resume_logging(socket.assigns.car.id)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:update_duration, socket) do
    Process.send_after(self(), :update_duration, :timer.seconds(1))
    {:noreply, assign(socket, duration: duration_str(socket.assigns.summary.since))}
  end

  def handle_info(:hide_error, socket) do
    {:noreply, assign(socket, error: nil, error_timeout: nil)}
  end

  def handle_info(summary, socket) do
    {:noreply, assign(socket, summary: summary, duration: duration_str(summary.since))}
  end

  defp translate_state(:start), do: nil
  defp translate_state(:driving), do: gettext("driving")
  defp translate_state(:charging), do: gettext("charging")
  defp translate_state(:charging_complete), do: gettext("charging complete")
  defp translate_state(:updating), do: gettext("updating")
  defp translate_state(:suspended), do: gettext("falling asleep")
  defp translate_state(:online), do: gettext("online")
  defp translate_state(:offline), do: gettext("offline")
  defp translate_state(:asleep), do: gettext("asleep")
  defp translate_state(:unavailable), do: gettext("unavailable")

  defp translate_error(:unlocked), do: gettext("Car is unlocked")
  defp translate_error(:sentry_mode), do: gettext("Sentry mode is enabled")
  defp translate_error(:shift_state), do: gettext("Shift state present")
  defp translate_error(:temp_reading), do: gettext("Temperature readings")
  defp translate_error(:preconditioning), do: gettext("Preconditioning")
  defp translate_error(:user_present), do: gettext("User present")
  defp translate_error(:update_in_progress), do: gettext("Update in progress")

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(ref) when is_reference(ref), do: Process.cancel_timer(ref)

  defp duration_str(nil), do: nil
  defp duration_str(date), do: DateTime.utc_now() |> DateTime.diff(date, :second) |> sec_to_str()

  @minute 60
  @hour @minute * 60
  @day @hour * 24
  @week @day * 7
  @divisor [@week, @day, @hour, @minute, 1]

  def sec_to_str(sec) when sec < 5, do: nil

  def sec_to_str(sec) do
    {_, [s, m, h, d, w]} =
      Enum.reduce(@divisor, {sec, []}, fn divisor, {n, acc} ->
        {rem(n, divisor), [div(n, divisor) | acc]}
      end)

    ["#{w} wk", "#{d} d", "#{h} hr", "#{m} min", "#{s} sec"]
    |> Enum.reject(&String.starts_with?(&1, "0"))
    |> Enum.take(2)
    |> Enum.join(", ")
  end
end
