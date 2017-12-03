#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Mutation.LoginEmployeeTest do
  use PlateSlateWeb.ConnCase, async: true

  alias PlateSlate.{Accounts, Repo}

  setup do
    user =
      %Accounts.User{}
      |> Accounts.User.changeset(%{role: "employee", name: "Bob",
        email: "bob@foo.com", password: "very-secret",
      })
      |> Repo.insert!
    {:ok, user: user}
  end

  @query """
  mutation {
    loginEmployee(email:"bob@foo.com",password:"very-secret") {
      token
      employee { name }
    }
  }
  """
  test "creating an employee session", %{user: user} do
    response = post(build_conn(), "/api", query: @query)

    assert %{"data" => %{ "loginEmployee" => %{
      "token" => token
    }}} = json_response(response, 200)

    assert {:ok, %{type: "employee",id: user.id,}} ==
      PlateSlateWeb.Authentication.verify(token)
  end
end
