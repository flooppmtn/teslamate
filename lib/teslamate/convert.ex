defmodule TeslaMate.Convert do
  @km_factor 0.62137119223733
  @ft_factor 3.28084

  def mph_to_kmh(nil), do: nil
  def mph_to_kmh(mph), do: round(mph / @km_factor)

  def miles_to_km(nil, _precision), do: nil
  def miles_to_km(miles = %Decimal{}, p), do: miles |> Decimal.div(Decimal.from_float(@km_factor)) |> Decimal.round(p)
  def miles_to_km(miles, 0), do: round(miles / @km_factor)
  def miles_to_km(miles, precision), do: Float.round(miles / @km_factor, precision)

  def km_to_miles(nil, _precision), do: nil
  def km_to_miles(km = %Decimal{}, p), do: km |> Decimal.mult(Decimal.from_float(@km_factor)) |> Decimal.round(p)
  def km_to_miles(km, 0), do: round(km * @km_factor)
  def km_to_miles(km, precision), do: Float.round(km * @km_factor, precision)

  def m_to_ft(nil), do: nil
  def m_to_ft(m), do: m * @ft_factor

  def ft_to_m(nil), do: nil
  def ft_to_m(ft), do: ft / @ft_factor

  def celsius_to_fahrenheit(nil, _precision), do: nil
  def celsius_to_fahrenheit(c, 0), do: round(c * 9 / 5 + 32)
  def celsius_to_fahrenheit(c, precision), do: Float.round(c * 9 / 5 + 32, precision)

  @minute 60
  @hour @minute * 60
  @day @hour * 24
  @week @day * 7
  @divisor [@week, @day, @hour, @minute, 1]

  def sec_to_str(sec) when is_number(sec) do
    {_, [s, m, h, d, w]} =
      Enum.reduce(@divisor, {sec, []}, fn divisor, {n, acc} ->
        {rem(n, divisor), [div(n, divisor) | acc]}
      end)

    ["#{w} wk", "#{d} d", "#{h} h", "#{m} min", "#{s} s"]
    |> Enum.reject(&String.starts_with?(&1, "0"))
    |> Enum.take(2)
  end
end
