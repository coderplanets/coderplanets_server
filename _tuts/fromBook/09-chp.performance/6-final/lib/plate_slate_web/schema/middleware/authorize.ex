#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Middleware.Authorize do
  @behaviour Absinthe.Middleware

  def call(resolution, role) do 
    with %{current_user: current_user} <- resolution.context,
    true <- correct_role?(current_user, role) do
      resolution
    else
      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "unauthorized"})
    end
  end

  defp correct_role?(%{}, :any), do: true
  defp correct_role?(%{role: role}, role), do: true
  defp correct_role?(_, _), do: false
end
