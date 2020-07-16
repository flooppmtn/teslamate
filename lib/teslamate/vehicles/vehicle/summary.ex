defmodule TeslaMate.Vehicles.Vehicle.Summary do
  import TeslaMate.Vehicles.Vehicle.Convert, only: [miles_to_km: 2, mph_to_kmh: 1]

  alias TeslaApi.Vehicle.State.{Drive, Charge}
  alias TeslaApi.Vehicle

  defstruct [
    :display_name,
    :state,
    :battery_level,
    :ideal_battery_range_km,
    :charge_energy_added,
    :speed
  ]

  def into(state, vehicle) do
    %__MODULE__{format_vehicle(vehicle) | state: format_state(state)}
  end

  defp format_state({:driving, _trip_id}), do: :driving
  defp format_state({:charging, "Charging", _process_id}), do: :charging
  defp format_state({:charging, "Complete", _process_id}), do: :charging_complete
  defp format_state({:updating, _update_id}), do: :updating
  defp format_state({:suspended, _}), do: :suspended
  defp format_state(state) when is_atom(state), do: state

  defp format_vehicle(%Vehicle{} = vehicle) do
    %__MODULE__{
      display_name: vehicle.display_name,
      speed: speed(vehicle),
      battery_level: battery_level(vehicle),
      ideal_battery_range_km: range_km(vehicle),
      charge_energy_added: energy_added(vehicle)
    }
  end

  defp energy_added(%Vehicle{charge_state: %Charge{charge_energy_added: kWh}}), do: kWh
  defp energy_added(_vehicle), do: nil

  defp battery_level(%Vehicle{charge_state: %Charge{battery_level: level}}), do: level
  defp battery_level(_vehicle), do: nil

  defp range_km(%Vehicle{charge_state: %Charge{ideal_battery_range: r}}), do: miles_to_km(r, 1)
  defp range_km(_vehicle), do: nil

  defp speed(%Vehicle{drive_state: %Drive{speed: s}}) when not is_nil(s), do: mph_to_kmh(s)
  defp speed(_vehicle), do: nil
end
