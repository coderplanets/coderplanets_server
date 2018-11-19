defmodule MastaniServer.Test.Query.CMS.Search do
  use MastaniServer.TestTools

  # alias MastaniServer.Accounts.User
  # alias MastaniServer.CMS
  # alias CMS.{Community}

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, _community} = db_insert(:community, %{title: "react"})
    {:ok, _community} = db_insert(:community, %{title: "php"})
    {:ok, _community} = db_insert(:community, %{title: "每日妹子"})
    {:ok, _community} = db_insert(:community, %{title: "javascript"})
    {:ok, _community} = db_insert(:community, %{title: "java"})

    {:ok, ~m(guest_conn)a}
  end

  describe "[cms search community query]" do
    @query """
    query($title: String!) {
      searchCommunities(title: $title) {
        entries {
          id
          title
        }
        totalCount
      }
    }
    """
    test "search community by full title should valid paged communities", ~m(guest_conn)a do
      variables = %{title: "react"}
      results = guest_conn |> query_result(@query, variables, "searchCommunities")

      assert results["totalCount"] == 1
      assert results["entries"] |> Enum.any?(&(&1["title"] == "react"))

      variables = %{title: "java"}
      results = guest_conn |> query_result(@query, variables, "searchCommunities")

      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["title"] == "java"))
      assert results["entries"] |> Enum.any?(&(&1["title"] == "javascript"))
    end

    test "search non-exsit community should get empty pagi data", ~m(guest_conn)a do
      variables = %{title: "non-exsit"}
      results = guest_conn |> query_result(@query, variables, "searchCommunities")

      assert results["totalCount"] == 0
      assert results["entries"] == []
    end
  end
end
