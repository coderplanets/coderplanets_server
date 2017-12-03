#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule Factory do
  def create_user(role) do
    int = :erlang.unique_integer([:positive, :monotonic])
    params = %{
      name: "Person #{int}",
      email: "fake-#{int}@foo.com",
      password: "super-secret",
      role: role
    }

    %PlateSlate.Accounts.User{}
    |> PlateSlate.Accounts.User.changeset(params)
    |> PlateSlate.Repo.insert!
  end
end
