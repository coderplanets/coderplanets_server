defmodule MastaniServer.Test.Mutation.StatisticsTest do
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.AssertHelper

  alias MastaniServer.Statistics
  # alias MastaniServer.Accounts.User
  alias Helper.ORM

  @valid_user mock_attrs(:user, %{nickname: "mydearxym"})

  setup do
    {:ok, user} = db_insert(:user, @valid_user)

    # Statistics.make_contribute(%User{id: user.id})

    token = mock_jwt_token(nickname: @valid_user.nickname)

    conn =
      build_conn()
      |> put_req_header("authorization", token)
      |> put_req_header("content-type", "application/json")

    conn_without_token = build_conn()

    {:ok, conn: conn, conn_without_token: conn_without_token, user: user}
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
    test "makeContribute should add record to user_contributes table", %{
      user: user,
      conn_without_token: conn
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
      conn_without_token: conn
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
