defmodule MastaniServer.Test.Query.Accounts.PublishedContents do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user community)a}
  end

  describe "[account favorited posts]" do
    @query """
    query($userId: ID!, $filter: PagedFilter!) {
      publishedPosts(userId: $userId, filter: $filter) {
        entries {
          id
          author {
            id
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published posts", ~m(guest_conn user community)a do
      pub_posts =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          post_attrs = mock_attrs(:post, %{community_id: community.id})
          {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

          acc ++ [post]
        end)

      random_post_id = pub_posts |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "publishedPosts")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_post_id))
    end
  end

  describe "[account favorited jobs]" do
    @query """
    query($userId: ID!, $filter: PagedFilter!) {
      publishedJobs(userId: $userId, filter: $filter) {
        entries {
          id
          author {
            id
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published jobs", ~m(guest_conn user community)a do
      pub_jobs =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          job_attrs = mock_attrs(:job, %{community_id: community.id})
          {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

          acc ++ [job]
        end)

      random_job_id = pub_jobs |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "publishedJobs")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_job_id))
    end
  end

  describe "[account favorited videos]" do
    @query """
    query($userId: ID!, $filter: PagedFilter!) {
      publishedVideos(userId: $userId, filter: $filter) {
        entries {
          id
          author {
            id
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published videos", ~m(guest_conn user community)a do
      pub_videos =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          video_attrs = mock_attrs(:video, %{community_id: community.id})
          {:ok, video} = CMS.create_content(community, :video, video_attrs, user)

          acc ++ [video]
        end)

      random_video_id = pub_videos |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "publishedVideos")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_video_id))
    end
  end

  describe "[account favorited repos]" do
    @query """
    query($userId: ID!, $filter: PagedFilter!) {
      publishedRepos(userId: $userId, filter: $filter) {
        entries {
          id
          author {
            id
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published repos", ~m(guest_conn user community)a do
      pub_repos =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          repo_attrs = mock_attrs(:repo, %{community_id: community.id})
          {:ok, repo} = CMS.create_content(community, :repo, repo_attrs, user)

          acc ++ [repo]
        end)

      random_repo_id = pub_repos |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "publishedRepos")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_repo_id))
    end
  end
end
