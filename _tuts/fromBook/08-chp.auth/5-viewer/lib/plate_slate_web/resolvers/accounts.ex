#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Resolvers.Accounts do
  alias PlateSlate.Accounts

  def login_employee(_, %{email: email, password: password}, _) do
    case Accounts.authenticate("employee", email, password) do
      {:ok, user} ->
        token = PlateSlateWeb.Authentication.sign(%{
          role: "employee", id: user.id
        })
        {:ok, %{token: token, employee: user}}
      _ ->
        {:error, "incorrect email or password"}
    end
  end

  def viewer(_, _, %{context: %{current_user: current_user}}) do
    {:ok, current_user}
  end
  def viewer(_, _, _) do
    {:ok, nil}
  end

end
