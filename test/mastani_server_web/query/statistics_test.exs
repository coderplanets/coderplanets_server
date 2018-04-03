defmodule MastaniServer.Test.Query.StatisticsTest do
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.AssertHelper

  alias MastaniServer.Statistics
  alias MastaniServer.Accounts.User

  @valid_user mock_attrs(:user, %{nickname: "mydearxym"})

  setup do
    {:ok, user} = db_insert(:user, @valid_user)

    Statistics.make_contribute(%User{id: user.id})

    token = mock_jwt_token(nickname: @valid_user.nickname)

    conn =
      build_conn()
      |> put_req_header("authorization", token)
      |> put_req_header("content-type", "application/json")

    conn_without_token = build_conn()

    {:ok, conn: conn, conn_without_token: conn_without_token, user: user}
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
      conn_without_token: conn
    } do
      variables = %{userId: user.id}
      results = conn |> query_result(@query, variables, "userContributes")

      assert is_list(results)
      assert ["count", "date"] == results |> List.first() |> Map.keys()
    end
  end
end
