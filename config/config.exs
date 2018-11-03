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

config :phoenix, :format_encoders, json: Jason
config :ecto, json_library: Jason

# TODO move this config to secret later
config :mastani_server, Helper.Guardian,
  issuer: "mastani_server",
  secret_key: "kSTPDbCUSRhiEmv86eYMUplL7xI5fDa/+6MWKzK2VYGxjwL0XGHHVJiSPNPe9hJe"

config :mastani_server, :mix_test_watch, exclude: [~r/docs\/.*/, ~r/deps\/.*/, ~r/mix.exs/]
# secret_key: {:system, "GUARDIAN_DEMO_SECRET_KEY"}

config :pre_commit, commands: ["format"], verbose: false
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

config :mastani_server, :general,
  page_size: 30,
  inner_page_size: 5,
  # today is not include
  community_contribute_days: 7,
  user_contribute_months: 6,
  default_subscribed_communities: 20,
  publish_throttle_interval_minutes: 3,
  publish_throttle_hour_limit: 20,
  publish_throttle_day_limit: 30,
  # user achievements
  user_achieve_star_weight: 1,
  user_achieve_watch_weight: 1,
  user_achieve_favorite_weight: 2,
  user_achieve_follow_weight: 3

config :mastani_server, :customization,
  theme: "cyan",
  community_chart: false,
  brainwash_free: false,
  banner_layout: "digest",
  contents_layout: "digest",
  content_divider: false,
  mark_viewed: true,
  display_density: "20"

config :mastani_server, MastaniServerWeb.Gettext, default_locale: "zh_CN", locales: ~w(en zh_CN)

import_config "#{Mix.env()}.exs"

if File.exists?("config/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end
