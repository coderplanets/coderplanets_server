#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import PlateSlateWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint PlateSlateWeb.Endpoint
    end
  end

  def auth_user(conn, user) do
    # hack so that xref errors don't happen on branches without this module
    token = apply(PlateSlateWeb.Authentication, :sign, [%{role: user.role, id: user.id}])
    conn
    |> Plug.Conn.put_req_header("Authorization", "Bearer #{token}")
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PlateSlate.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(PlateSlate.Repo, {:shared, self()})
    end
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

end
