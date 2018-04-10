defmodule MastaniServer.Test.Query.StatisticsTest do
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper

  alias MastaniServer.Statistics
  alias MastaniServer.Accounts.User
  import ShortMaps

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)

    Statistics.make_contribute(%User{id: user.id})

    {:ok, ~m(guest_conn user)a}
  end

  describe "[statistics query user_contributes] " do
    @query """
    query userContributes($id: ID!) {
      userContributes(id: $id) {
        date
        count
      }
    }
    """
    test "query userContributes get valid count/date list", ~m(guest_conn user)a do
      variables = %{id: user.id}
      results = guest_conn |> query_result(@query, variables, "userContributes")

      assert is_list(results)
      assert ["count", "date"] == results |> List.first() |> Map.keys()
    end
  end
end
