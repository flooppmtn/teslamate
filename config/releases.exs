import Config

defmodule Util do
  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.encode64() |> binary_part(0, length)
  end

  def validate_namespace!(nil), do: nil
  def validate_namespace!(""), do: nil

  def validate_namespace!(ns) when is_binary(ns) do
    case String.contains?(ns, "/") do
      true -> raise "MQTT_NAMESPACE must not contain '/'"
      false -> ns
    end
  end

  def parse_check_origin!("true"), do: true
  def parse_check_origin!("false"), do: false
  def parse_check_origin!(hosts) when is_binary(hosts), do: String.split(hosts, ",")
  def parse_check_origin!(hosts), do: raise("Invalid check_origin option: #{inspect(hosts)}")

  def validate_import_dir(nil), do: nil

  def validate_import_dir(path) do
    case File.ls(path) do
      {:ok, [_ | _]} ->
        path

      {:ok, []} ->
        nil

      {:error, :enoent} ->
        nil

      {:error, reason} ->
        IO.puts("Cannot access directory '#{path}': #{inspect(reason)}")
        nil
    end
  end

  def choose_http_binding_address() do
    defaults = [transport_options: [socket_opts: [:inet6]]]

    case System.get_env("HTTP_BINDING_ADDRESS", "") do
      "" ->
        defaults

      address ->
        case :inet.parse_address(to_charlist(address)) do
          {:ok, ip} ->
            [ip: ip]

          {:error, reason} ->
            IO.puts("Cannot parse HTTP_BINDING_ADDRESS '#{address}': #{inspect(reason)}")
            defaults
        end
    end
  end
end

config :teslamate, TeslaMate.Repo,
  username: System.fetch_env!("DATABASE_USER"),
  password: System.fetch_env!("DATABASE_PASS"),
  database: System.fetch_env!("DATABASE_NAME"),
  hostname: System.fetch_env!("DATABASE_HOST"),
  port: System.get_env("DATABASE_PORT", "5432"),
  ssl: System.get_env("DATABASE_SSL", "false") == "true",
  pool_size: System.get_env("DATABASE_POOL_SIZE", "10") |> String.to_integer(),
  timeout: System.get_env("DATABASE_TIMEOUT", "60000") |> String.to_integer()

config :teslamate, TeslaMateWeb.Endpoint,
  http: Util.choose_http_binding_address() ++ [port: System.get_env("PORT", "4000")],
  url: [host: System.get_env("VIRTUAL_HOST", "localhost"), port: 80],
  secret_key_base: System.get_env("SECRET_KEY_BASE", Util.random_string(64)),
  live_view: [signing_salt: System.get_env("SIGNING_SALT", Util.random_string(8))],
  check_origin: System.get_env("CHECK_ORIGIN", "false") |> Util.parse_check_origin!()

if System.get_env("DISABLE_MQTT") != "true" do
  config :teslamate, :mqtt,
    host: System.fetch_env!("MQTT_HOST"),
    username: System.get_env("MQTT_USERNAME"),
    password: System.get_env("MQTT_PASSWORD"),
    tls: System.get_env("MQTT_TLS"),
    accept_invalid_certs: System.get_env("MQTT_TLS_ACCEPT_INVALID_CERTS"),
    namespace: System.get_env("MQTT_NAMESPACE") |> Util.validate_namespace!()
end

config :logger,
  level: :info,
  compile_time_purge_matching: [[level_lower_than: :info]]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:car_id]

config :teslamate, :srtm_cache, System.get_env("SRTM_CACHE", ".srtm_cache")

config :teslamate,
  import_directory: System.get_env("IMPORT_DIR", "import") |> Util.validate_import_dir()
