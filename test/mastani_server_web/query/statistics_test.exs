defmodule MastaniServer.Test.Query.StatisticsTest do
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper

  alias MastaniServer.Statistics
  alias MastaniServer.Accounts.User

  setup do
    {:ok, user} = db_insert(:user)

    guest_conn = mock_conn(:guest)

    Statistics.make_contribute(%User{id: user.id})

    {:ok, guest_conn: guest_conn, user: user}
  end

  describe "[statistics query user_contributes] " do
    @query """
    query userContributes($userId: ID!) {
      userContributes(userId: $userId) {
        date
        count
      }
    }
    """
    test "query userContributes get valid count/date list", %{
      user: user,
      guest_conn: conn
    } do
      variables = %{userId: user.id}
      results = conn |> query_result(@query, variables, "userContributes")

      assert is_list(results)
      assert ["count", "date"] == results |> List.first() |> Map.keys()
    end
  end
end
