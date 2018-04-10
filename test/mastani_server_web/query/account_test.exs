defmodule MastaniServer.Test.Query.AccountTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user)a}
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
    test "query a account works", ~m(guest_conn user)a do
      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "user")
      assert results["id"] == to_string(user.id)
      assert results["nickname"] == user.nickname
    end
  end
end
