defmodule GroupherServer.Test.Query.Accounts.Search do
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.Model.User
  # alias GroupherServer.CMS

  setup do
    guest_conn = simu_conn(:guest)

    {:ok, _community} = db_insert(:user, %{nickname: "react"})
    {:ok, _community} = db_insert(:user, %{nickname: "php"})
    {:ok, _community} = db_insert(:user, %{nickname: "每日妹子"})
    {:ok, _community} = db_insert(:user, %{nickname: "javascript"})
    {:ok, _community} = db_insert(:user, %{nickname: "java"})

    {:ok, ~m(guest_conn)a}
  end

  describe "[cms search post query]" do
    @query """
    query($name: String!) {
      searchUsers(name: $name) {
        entries {
          id
          nickname
        }
        totalCount
      }
    }
    """
    test "search user by full nickname should valid paged communities", ~m(guest_conn)a do
      variables = %{name: "react"}
      results = guest_conn |> query_result(@query, variables, "searchUsers")

      assert results["totalCount"] == 1
      assert results["entries"] |> Enum.any?(&(&1["nickname"] == "react"))

      variables = %{name: "java"}
      results = guest_conn |> query_result(@query, variables, "searchUsers")

      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["nickname"] == "java"))
      assert results["entries"] |> Enum.any?(&(&1["nickname"] == "javascript"))
    end

    test "search non-exsit user should get empty pagi data", ~m(guest_conn)a do
      variables = %{name: "non-exsit"}
      results = guest_conn |> query_result(@query, variables, "searchUsers")

      assert results["totalCount"] == 0
      assert results["entries"] == []
    end
  end
end
