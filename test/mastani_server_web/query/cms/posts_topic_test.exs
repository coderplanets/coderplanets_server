defmodule MastaniServer.Test.Query.PostsTopic do
  use MastaniServer.TestTools

  # import Helper.Utils, only: [get_config: 2]
  alias MastaniServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    post_attrs = mock_attrs(:post, %{community_id: community.id})
    {:ok, _post} = CMS.create_content(community, :post, post_attrs, user, %{topic: "index"})
    post_attrs = mock_attrs(:post, %{community_id: community.id})
    {:ok, _post} = CMS.create_content(community, :post, post_attrs, user, %{topic: "index"})

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user community)a}
  end

  describe "[query posts topic filter]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          title
        }
        totalCount
      }
    }
    """
    test "topic filter on posts should work", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      assert results["totalCount"] == 2

      variables = %{filter: %{page: 1, size: 10, topic: "index"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      assert results["totalCount"] == 2

      variables = %{filter: %{page: 1, size: 10, topic: "city"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      assert results["totalCount"] == 0
    end
  end

  describe "[query non-posts topic filter]" do
    @query """
    query($filter: PagedArticleFilter!) {
      pagedJobs(filter: $filter) {
        entries {
          id
          title
        }
        totalCount
      }
    }
    """
    test "topic filter on non-posts has no effect", ~m(guest_conn user community)a do
      job_attrs = mock_attrs(:job, %{community_id: community.id})
      {:ok, _} = CMS.create_content(community, :job, job_attrs, user, %{topic: "index"})

      job_attrs = mock_attrs(:job, %{community_id: community.id})
      {:ok, _} = CMS.create_content(community, :job, job_attrs, user, %{topic: "city"})

      variables = %{filter: %{community: community.raw, page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")
      assert results["totalCount"] == 2

      variables = %{filter: %{page: 1, size: 10, topic: "index"}}
      assert guest_conn |> query_get_error?(@query, variables)
    end
  end
end
