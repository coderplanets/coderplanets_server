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

# TODO move this config to secret later
config :mastani_server, Helper.MastaniServer.Guardian,
  issuer: "mastani_server",
  secret_key: "kSTPDbCUSRhiEmv86eYMUplL7xI5fDa/+6MWKzK2VYGxjwL0XGHHVJiSPNPe9hJe"

config :mastani_server, :mix_test_watch, exclude: [~r/docs\/.*/, ~r/deps\/.*/, ~r/mix.exs/]
# secret_key: {:system, "GUARDIAN_DEMO_SECRET_KEY"}

config :pre_commit, commands: ["format"], verbose: false
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
config :mastani_server, :pagi,
  page_size: 30,
  inner_page_size: 20

import_config "#{Mix.env()}.exs"

if File.exists?("config/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end
