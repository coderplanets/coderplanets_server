# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.Statistics.MakeContribute do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function
  alias MastaniServer.Statistics
  alias MastaniServer.CMS.Community
  alias MastaniServer.Accounts.User

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(%{value: nil, errors: _} = resolution, _), do: resolution

  def call(%{value: value, context: %{cur_user: cur_user}} = resolution, for: threads) do
    case is_list(threads) do
      true ->
        if :user in threads, do: Statistics.make_contribute(%User{id: cur_user.id})
        if :community in threads, do: Statistics.make_contribute(%Community{id: value.id})

      false ->
        if :user == threads, do: Statistics.make_contribute(%User{id: cur_user.id})
        if :community == threads, do: Statistics.make_contribute(%Community{id: value.id})
    end

    resolution
  end
end
