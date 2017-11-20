use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mastani_server, MastaniServerWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :mastani_server, MastaniServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "mastani_server_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
