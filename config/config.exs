# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :mastani_server, ecto_repos: [MastaniServer.Repo]

# Configures the endpoint
config :mastani_server, MastaniServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Ru3N3sehqeuFjBV2Z6k7FuyA59fH8bWm8D4aZWu2RifP3xKMBYo3YRILrnXAGezM",
  render_errors: [view: MastaniServerWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: MastaniServer.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mastani_server, MastaniServer.Utils.Guardian,
  issuer: "mastani_server",
  secret_key: "kSTPDbCUSRhiEmv86eYMUplL7xI5fDa/+6MWKzK2VYGxjwL0XGHHVJiSPNPe9hJe"

# secret_key: {:system, "GUARDIAN_DEMO_SECRET_KEY"}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
