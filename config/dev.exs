use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :groupher_server, GroupherServerWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("SERVE_PORT") || "7001")],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4001, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# You can generate a new secret by running:
# mix phx.gen.secret
config :groupher_server, GroupherServerWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# should use RDS 内网地址
config :groupher_server, GroupherServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_NAME" || "cps_server_dev"),
  hostname: System.get_env("DB_HOST"),
  port: String.to_integer(System.get_env("DB_PORT") || "3433"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE") || "20")

config :groupher_server, :github_oauth,
  client_id: System.get_env("OAUTH_GITHUB_CLIENT_ID"),
  client_secret: System.get_env("OAUTH_GITHUB_CLIENT_SECRET")
