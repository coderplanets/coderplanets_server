defmodule MastaniServerWeb.Router do
  use MastaniServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", MastaniServerWeb do
    pipe_through :api
  end

  scope "/" do
    pipe_through :api

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: MastaniServerWeb.Schema,
      interface: :simple,
      context: %{pubsub: MastaniServerWeb.Endpoint}
  end
end
