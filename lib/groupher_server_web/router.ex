defmodule GroupherServerWeb.Router do
  @moduledoc false

  use GroupherServerWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(GroupherServerWeb.Context)
  end

  alias GroupherServerWeb.Controller

  scope "/api" do
    pipe_through(:api)

    # get "/og-info", TodoController, only: [:index]
    # resources("/og-info", OG, only: [:index])
    get("/og-info", Controller.OG, :index)
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
