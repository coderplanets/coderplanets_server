use Mix.Config

config :mastani_server, MastaniServerWeb.Endpoint,
  http: [port: 4001],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

# Configure your database
config :mastani_server, MastaniServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "mastani_server_mock",
  hostname: "localhost",
  # port: 3433,
  pool_size: 10
