# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.Statistics.MakeContribute do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function
  alias MastaniServer.Statistics
  alias MastaniServer.Accounts.User

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(%{value: nil, errors: _} = resolution, _), do: resolution

  def call(%{value: _, context: %{cur_user: cur_user}} = resolution, _) do
    Statistics.make_contribute(%User{id: cur_user.id})
    resolution
  end
end
