defmodule GroupherServer.Test.Query.CMS.Search do
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.Model.User
  alias GroupherServer.CMS

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, _community} = db_insert(:community, %{title: "react"})
    {:ok, _community} = db_insert(:community, %{title: "php"})
    {:ok, _community} = db_insert(:community, %{title: "每日妹子"})
    {:ok, _community} = db_insert(:community, %{title: "javascript"})
    {:ok, _community} = db_insert(:community, %{title: "java"})

    {:ok, _community} = db_insert(:post, %{title: "react"})
    {:ok, _community} = db_insert(:post, %{title: "php"})
    {:ok, _community} = db_insert(:post, %{title: "每日妹子"})
    {:ok, _community} = db_insert(:post, %{title: "javascript"})
    {:ok, _community} = db_insert(:post, %{title: "java"})

    {:ok, _community} = db_insert(:job, %{title: "react"})
    {:ok, _community} = db_insert(:job, %{title: "php"})
    {:ok, _community} = db_insert(:job, %{title: "每日妹子"})
    {:ok, _community} = db_insert(:job, %{title: "javascript"})
    {:ok, _community} = db_insert(:job, %{title: "java"})

    {:ok, _community} = db_insert(:repo, %{title: "react"})
    {:ok, _community} = db_insert(:repo, %{title: "php"})
    {:ok, _community} = db_insert(:repo, %{title: "每日妹子"})
    {:ok, _community} = db_insert(:repo, %{title: "javascript"})
    {:ok, _community} = db_insert(:repo, %{title: "java"})

    {:ok, ~m(guest_conn)a}
  end

  describe "[cms search post query]" do
    @query """
    query($title: String!) {
      searchPosts(title: $title) {
        entries {
          id
          title
        }
        totalCount
      }
    }
    """
    test "search post by full title should valid paged communities", ~m(guest_conn)a do
      variables = %{title: "react"}
      results = guest_conn |> query_result(@query, variables, "searchPosts")

      assert results["totalCount"] == 1
      assert results["entries"] |> Enum.any?(&(&1["title"] == "react"))

      variables = %{title: "java"}
      results = guest_conn |> query_result(@query, variables, "searchPosts")

      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["title"] == "java"))
      assert results["entries"] |> Enum.any?(&(&1["title"] == "javascript"))
    end

    test "search non-exsit post should get empty pagi data", ~m(guest_conn)a do
      variables = %{title: "non-exsit"}
      results = guest_conn |> query_result(@query, variables, "searchPosts")

      assert results["totalCount"] == 0
      assert results["entries"] == []
    end
  end

  describe "[cms search job query]" do
    @query """
    query($title: String!) {
      searchJobs(title: $title) {
        entries {
          id
          title
        }
        totalCount
      }
    }
    """
    test "search job by full title should valid paged communities", ~m(guest_conn)a do
      variables = %{title: "react"}
      results = guest_conn |> query_result(@query, variables, "searchJobs")

      assert results["totalCount"] == 1
      assert results["entries"] |> Enum.any?(&(&1["title"] == "react"))

      variables = %{title: "java"}
      results = guest_conn |> query_result(@query, variables, "searchJobs")

      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["title"] == "java"))
      assert results["entries"] |> Enum.any?(&(&1["title"] == "javascript"))
    end

    test "search non-exsit job should get empty pagi data", ~m(guest_conn)a do
      variables = %{title: "non-exsit"}
      results = guest_conn |> query_result(@query, variables, "searchJobs")

      assert results["totalCount"] == 0
      assert results["entries"] == []
    end
  end

  describe "[cms search repo query]" do
    @query """
    query($title: String!) {
      searchRepos(title: $title) {
        entries {
          id
          title
        }
        totalCount
      }
    }
    """
    test "search repo by full title should valid paged communities", ~m(guest_conn)a do
      variables = %{title: "react"}
      results = guest_conn |> query_result(@query, variables, "searchRepos")

      assert results["totalCount"] == 1
      assert results["entries"] |> Enum.any?(&(&1["title"] == "react"))

      variables = %{title: "java"}
      results = guest_conn |> query_result(@query, variables, "searchRepos")

      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["title"] == "java"))
      assert results["entries"] |> Enum.any?(&(&1["title"] == "javascript"))
    end

    test "search non-exsit repo should get empty pagi data", ~m(guest_conn)a do
      variables = %{title: "non-exsit"}
      results = guest_conn |> query_result(@query, variables, "searchRepos")

      assert results["totalCount"] == 0
      assert results["entries"] == []
    end
  end

  describe "[cms search community query]" do
    @query """
    query($title: String!, $category: String) {
      searchCommunities(title: $title, category: $category) {
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

    test "can search community with category", ~m(guest_conn)a do
      {:ok, community} = db_insert(:community, %{title: "cool-pl"})
      {:ok, category} = db_insert(:category, %{raw: "pl"})

      {:ok, _} = CMS.set_category(community, category)

      variables = %{title: "cool-pl", category: "pl"}
      results = guest_conn |> query_result(@query, variables, "searchCommunities")

      assert results["totalCount"] == 1
      assert results["entries"] |> Enum.any?(&(&1["title"] == "cool-pl"))
    end

    test "search non-exsit community should get empty pagi data", ~m(guest_conn)a do
      variables = %{title: "non-exsit"}
      results = guest_conn |> query_result(@query, variables, "searchCommunities")

      assert results["totalCount"] == 0
      assert results["entries"] == []
    end
  end
end
