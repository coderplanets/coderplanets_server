defmodule MastaniServer.Test.Mutation.StatisticsTest do
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper

  alias MastaniServer.Statistics
  # alias MastaniServer.Accounts.User
  alias Helper.ORM

  setup do
    guest_conn = mock_conn(:guest)

    {:ok, user} = db_insert(:user)
    {:ok, user: user, guest_conn: guest_conn}
  end

  describe "[statistics mutaion user_contributes] " do
    @query """
    mutation makeContrubute($userId: ID!) {
      makeContrubute(userId: $userId) {
        date
        count
      }
    }
    """
    test "for guest user makeContribute should add record to user_contributes table", %{
      user: user,
      guest_conn: conn
    } do
      variables = %{userId: user.id}
      assert {:error, _} = ORM.find_by(Statistics.UserContributes, user_id: user.id)
      results = conn |> mutation_result(@query, variables, "makeContrubute")
      assert {:ok, _} = ORM.find_by(Statistics.UserContributes, user_id: user.id)

      assert ["count", "date"] == results |> Map.keys()
      assert results["date"] == Timex.today() |> Date.to_iso8601()
      assert results["count"] == 1
    end

    test "makeContribute to same user should update contribute count", %{
      user: user,
      guest_conn: conn
    } do
      variables = %{userId: user.id}
      conn |> mutation_result(@query, variables, "makeContrubute")
      results = conn |> mutation_result(@query, variables, "makeContrubute")
      assert ["count", "date"] == results |> Map.keys()
      assert results["date"] == Timex.today() |> Date.to_iso8601()
      assert results["count"] == 2
    end
  end
end
