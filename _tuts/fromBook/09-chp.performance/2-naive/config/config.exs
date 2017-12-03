#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :comeonin, Ecto.Password, Comeonin.Pbkdf2

# General application configuration
config :plate_slate,
  ecto_repos: [PlateSlate.Repo]

# Configures the endpoint
config :plate_slate, PlateSlateWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JbSS+mF2qR3w+3PdYK4g4uBwTA48ZGF6sHpkt0tynRf4EIyrMp0aPb1CAmMgkrkL",
  render_errors: [view: PlateSlateWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: PlateSlate.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
