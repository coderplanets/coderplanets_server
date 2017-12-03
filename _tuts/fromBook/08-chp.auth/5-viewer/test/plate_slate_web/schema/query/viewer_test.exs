#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Query.ViewerTest do
  use PlateSlateWeb.ConnCase, async: true

  alias PlateSlate.{Accounts, Repo}

  setup do
    user =
      %Accounts.User{}
      |> Accounts.User.changeset(
        %{role: "employee", name: "Bob",
          email: "bob@foo.com", password: "very-secret",
        })
        |> Repo.insert!
    {:ok, user: user}
  end

  @query """
  query {
    viewer {
      ... on Employee { name }
      ... on Customer { name }
    }
  }
  """
  test "getting the viewer with a valid token", %{user: user} do
    conn = build_conn() |> auth_user(user)
    response = post(conn, "/api", query: @query)
    assert %{"data" => %{"viewer" => %{"name" => "Bob"}}} =
      json_response(response, 200)
  end
  test "getting the viewer without a valid token" do
    response = post(build_conn(), "/api", query: @query)
    assert %{"data" => %{"viewer" => nil}} =
      json_response(response, 200)
  end

  defp auth_user(conn, user) do
    token = PlateSlateWeb.Authentication.sign(%{role: user.role, id: user.id})
    put_req_header(conn, "authorization", "Bearer #{token}")
  end

end
