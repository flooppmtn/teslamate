# MQTT Integration

## Introduction

The MQTT function within TeslaMate allows useful values to be published to an MQTT broker. This is useful in allowing other automation platforms to consume data from TeslaMate.

## MQTT Topics

Vehicle data will be published to the following topics (`$car_id` usually starts at 1):

| Topic                                                  | Example              | Description                                                  |
| ------------------------------------------------------ | -------------------- | ------------------------------------------------------------ |
| `teslamate/cars/$car_id/display_name`                  | Blue Thunder         | Vehicle Name                                                 |
| `teslamate/cars/$car_id/state`                         | asleep               | Status of the vehicle (e.g. `onlilne`, `asleep`, `charging`) |
| `teslamate/cars/$car_id/healthy`                       | true                 | Health status of the logger for that vehicle                 |
| `teslamate/cars/$car_id/version`                       | 2019.32.12.2 58f3b76 | Software Version                                             |
| `teslamate/cars/$car_id/update_available`              | false                | Indicates if a software update is available                  |
|                                                        |                      |                                                              |
| `teslamate/cars/$car_id/latitude`                      | 35.278131            | Last reported car latitude                                   |
| `teslamate/cars/$car_id/longitude`                     | 29.744801            | Last reported car longitude                                  |
| `teslamate/cars/$car_id/shift_state`                   | D                    | Current/Last Shift State (D/N/R/P)                           |
| `teslamate/cars/$car_id/speed`                         | 12                   | Current Speed in km/h                                        |
|                                                        |                      |                                                              |
| `teslamate/cars/$car_id/locked`                        | true                 | Indicates if the car is locked                               |
| `teslamate/cars/$car_id/sentry_mode`                   | false                | Indicates if Sentry Mode is active                           |
| `teslamate/cars/$car_id/windows_open`                  | false                | Indicates if any of the windows are open                     |
|                                                        |                      |                                                              |
| `teslamate/cars/$car_id/is_climate_on`                 | true                 | Indicates if the climate control is on                       |
| `teslamate/cars/$car_id/inside_temp`                   | 20.8                 | Inside Temperature in °C                                     |
| `teslamate/cars/$car_id/outside_temp`                  | 18.4                 | Temperature in °C                                            |
|                                                        |                      |                                                              |
| `teslamate/cars/$car_id/odometer`                      | 1653                 | Car odometer in km                                           |
| `teslamate/cars/$car_id/est_battery_range_km`          | 372.5                | Estimated Range in km                                        |
| `teslamate/cars/$car_id/rated_battery_range_km`        | 401.63               | Rated Range in km                                            |
| `teslamate/cars/$car_id/ideal_battery_range_km`        | 335.79               | Ideal Range in km                                            |
|                                                        |                      |                                                              |
| `teslamate/cars/$car_id/battery_level`                 | 88                   | Battery Level Percentage                                     |
| `teslamate/cars/$car_id/plugged_in`                    | true                 | If car is currently plugged into a charger                   |
| `teslamate/cars/$car_id/charge_energy_added`           | 5.06                 | Last added energy in kW                                      |
| `teslamate/cars/$car_id/charge_limit_soc`              | 90                   | Charge Limit Configured in Percentage                        |
| `teslamate/cars/$car_id/charge_port_door_open`         | true                 | Indicates if the charger door is open                        |
| `teslamate/cars/$car_id/charger_actual_current`        | 2.05                 | Current amperage supplied by charger                         |
| `teslamate/cars/$car_id/charger_phases`                | 3                    | Number of charger power phases (1-3)                         |
| `teslamate/cars/$car_id/charger_power`                 | 48.9                 | Charger Power                                                |
| `teslamate/cars/$car_id/charger_voltage`               | 240                  | Charger Voltage                                              |
| `teslamate/cars/$car_id/scheduled_charging_start_time` | 2019-02-29T23:00:07Z | Start time of the scheduled charge                           |
| `teslamate/cars/$car_id/time_to_full_charge`           | 0.0                  | Seconds remaining to full charge                             |
