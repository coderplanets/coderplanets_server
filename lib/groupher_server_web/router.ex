defmodule GroupherServerWeb.Router do
  @moduledoc false

  use GroupherServerWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  # see https://github.com/sikanhe/apollo-tracing-elixir/issues/26
  require Protocol
  Protocol.derive(Jason.Encoder, ApolloTracing.Schema)
  Protocol.derive(Jason.Encoder, ApolloTracing.Schema.Execution)

  pipeline :api do
    plug(:accepts, ["json"])
    plug(GroupherServerWeb.Context)
  end

  scope "/graphiql" do
    pipe_through(:api)

    forward(
      "/",
      Absinthe.Plug.GraphiQL,
      schema: GroupherServerWeb.Schema,
      json_codec: Jason,
      pipeline: {ApolloTracing.Pipeline, :plug},
      interface: :playground,
      context: %{pubsub: GroupherServerWeb.Endpoint}
    )
  end
end
