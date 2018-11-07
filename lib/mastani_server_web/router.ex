defmodule MastaniServerWeb.Router do
  use MastaniServerWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug(Helper.PublicIpPlug)
    plug(:accepts, ["json"])
    plug(MastaniServerWeb.Context)
  end

  scope "/graphiql" do
    pipe_through(:api)

    forward(
      "/",
      Absinthe.Plug.GraphiQL,
      schema: MastaniServerWeb.Schema,
      # json_codec: Jason,
      pipeline: {ApolloTracing.Pipeline, :plug},
      interface: :playground,
      context: %{pubsub: MastaniServerWeb.Endpoint}
    )
  end
end
