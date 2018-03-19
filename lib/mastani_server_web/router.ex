defmodule MastaniServerWeb.Router do
  use MastaniServerWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(MastaniServerWeb.Context)
  end

  scope "/api", MastaniServerWeb do
    pipe_through(:api)
  end

  scope "/" do
    pipe_through(:api)

    forward(
      "/graphiql",
      Absinthe.Plug.GraphiQL,
      schema: MastaniServerWeb.Schema,
      pipeline: {ApolloTracing.Pipeline, :plug},
      interface: :playground,
      context: %{pubsub: MastaniServerWeb.Endpoint}
    )
  end
end
