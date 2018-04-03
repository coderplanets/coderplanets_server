# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.Statistics.MakeContribute do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function
  alias MastaniServer.Statistics
  alias MastaniServer.Accounts.User

  def call(%{value: nil} = resolution, _) do
    IO.inspect("MakeContribute nil")
    resolution
  end

  def call(%{value: _, context: %{current_user: current_user}} = resolution, _) do
    # IO.inspect value, label: "MakeContribute"
    # IO.inspect current_user.id, label: "current_user"
    Statistics.make_contribute(%User{id: current_user.id})
    resolution
  end
end
