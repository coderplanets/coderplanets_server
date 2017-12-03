#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Router do
  use PlateSlateWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug PlateSlateWeb.Context
  end

  scope "/admin", PlateSlateWeb do
    pipe_through :browser

    resources "/items", ItemController
  end

  scope "/" do
    pipe_through :api

    forward "/api", Absinthe.Plug,
      schema: PlateSlateWeb.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: PlateSlateWeb.Schema,
      socket: PlateSlateWeb.UserSocket
  end

end
