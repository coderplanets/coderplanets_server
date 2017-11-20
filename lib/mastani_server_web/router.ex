defmodule MastaniServerWeb.Router do
  use MastaniServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", MastaniServerWeb do
    pipe_through :api
  end
end
