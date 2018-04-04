defmodule MastaniServer.Test.Query.AccountTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = mock_conn(:guest)

    {:ok, user: user, guest_conn: guest_conn}
  end

  describe "[account test]" do
    @query """
    query user($id: ID!) {
      user(id: $id) {
        id
        nickname
        bio
      }
    }
    """
    test "query a account works", %{user: user, guest_conn: conn} do
      variables = %{id: user.id}
      results = conn |> query_result(@query, variables, "user")
      assert results["id"] == to_string(user.id)
      assert results["nickname"] == user.nickname
    end
  end
end
