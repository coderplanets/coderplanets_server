defmodule MastaniServer.Test.Query.Statistics do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts.User
  alias MastaniServer.Statistics

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)

    Statistics.make_contribute(%User{id: user.id})

    {:ok, ~m(guest_conn user)a}
  end

  describe "[statistics query user_contribute] " do
    @query """
    query($id: ID!) {
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
