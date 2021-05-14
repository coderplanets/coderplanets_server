defmodule GroupherServer.Test.Query.CMS.ContentCounts do
  use GroupherServer.TestTools

  # alias GroupherServer.Accounts.User
  alias GroupherServer.CMS

  setup do
    guest_conn = simu_conn(:guest)
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)

    {:ok, ~m(guest_conn community user)a}
  end

  describe "[cms contents count]" do
    @query """
    query($id: ID) {
      community(id: $id) {
        id
        title
        postsCount
      }
    }
    """
    test "community have valid posts_count", ~m(guest_conn community user)a do
      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")
      assert results["postsCount"] == 0

      count = Enum.random(1..20)

      Enum.reduce(1..count, [], fn _, acc ->
        post_attrs = mock_attrs(:post, %{community_id: community.id})
        {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
        acc ++ [post]
      end)

      results = guest_conn |> query_result(@query, variables, "community")
      assert results["postsCount"] == count
    end

    @query """
    query($id: ID) {
      community(id: $id) {
        id
        title
        jobsCount
      }
    }
    """
    test "community have valid jobs_count", ~m(guest_conn community user)a do
      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")
      assert results["jobsCount"] == 0

      count = Enum.random(1..20)

      Enum.reduce(1..count, [], fn _, acc ->
        job_attrs = mock_attrs(:job, %{community_id: community.id})
        {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

        acc ++ [job]
      end)

      results = guest_conn |> query_result(@query, variables, "community")
      assert results["jobsCount"] == count
    end

    @query """
    query($id: ID) {
      community(id: $id) {
        id
        title
        reposCount
      }
    }
    """
    test "community have valid repos_count", ~m(guest_conn community user)a do
      variables = %{id: community.id}
      results = guest_conn |> query_result(@query, variables, "community")
      assert results["reposCount"] == 0

      count = Enum.random(1..20)

      Enum.reduce(1..count, [], fn _, acc ->
        repo_attrs = mock_attrs(:repo, %{community_id: community.id})
        {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

        acc ++ [repo]
      end)

      results = guest_conn |> query_result(@query, variables, "community")
      assert results["reposCount"] == count
    end
  end
end
