defmodule MastaniServer.Test.Query.PostsTopic do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    post_attrs = mock_attrs(:post, %{community_id: community.id, topic: "posts"})
    {:ok, _post} = CMS.create_content(community, :post, post_attrs, user)
    post_attrs = mock_attrs(:post, %{community_id: community.id, topic: "posts"})
    {:ok, _post} = CMS.create_content(community, :post, post_attrs, user)

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user community)a}
  end

  describe "[query posts topic filter]" do
    @create_post_query """
    mutation(
      $title: String!
      $body: String!
      $digest: String!
      $length: Int!
      $communityId: ID!
      $tags: [Ids]
      $topic: CmsTopic
    ) {
      createPost(
        title: $title
        body: $body
        digest: $digest
        length: $length
        communityId: $communityId
        tags: $tags
        topic: $topic
      ) {
        title
        body
        id
      }
    }
    """
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
    test "create post with valid args and topic ", ~m(guest_conn)a do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      {:ok, community} = db_insert(:community)
      post_attr = mock_attrs(:post)

      variables = post_attr |> Map.merge(%{communityId: community.id, topic: "city"})
      _created = user_conn |> mutation_result(@create_post_query, variables, "createPost")

      variables = %{filter: %{page: 1, size: 10, topic: "city"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results["totalCount"] == 1
    end

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

      variables = %{filter: %{page: 1, size: 10, topic: "posts"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      assert results["totalCount"] == 2

      variables = %{filter: %{page: 1, size: 10, topic: "other"}}
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
      job_attrs = mock_attrs(:job, %{community_id: community.id, topic: "posts"})
      {:ok, _} = CMS.create_content(community, :job, job_attrs, user)

      job_attrs = mock_attrs(:job, %{community_id: community.id, topic: "city"})
      {:ok, _} = CMS.create_content(community, :job, job_attrs, user)

      variables = %{filter: %{community: community.raw, page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")
      assert results["totalCount"] == 2

      variables = %{filter: %{page: 1, size: 10, topic: "posts"}}
      assert guest_conn |> query_get_error?(@query, variables)
    end
  end
end
