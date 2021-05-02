# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule GroupherServerWeb.Middleware.AchievementProof do
  @moduledoc """
  add default achievement for user
  """

  @behaviour Absinthe.Middleware

  def call(%{value: nil} = resolution, _) do
    value = %{
      reputation: 0,
      articles_upvotes_count: 0,
      articles_collects_count: 0,
      donate_member: false,
      senior_member: false,
      sponsor_member: false,
      source_contribute: %{
        web: false,
        server: false,
        weApp: false,
        h5: false,
        mobile: false
      }
    }

    %{resolution | value: value}
  end

  def call(resolution, _), do: resolution
end
