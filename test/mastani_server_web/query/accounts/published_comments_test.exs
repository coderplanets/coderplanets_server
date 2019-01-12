defmodule MastaniServer.Test.Query.Accounts.PublishedComments do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user)a}
  end

  describe "[account published comments on post]" do
    @query """
    query($userId: ID!, $filter: PagedFilter!) {
      publishedPostComments(userId: $userId, filter: $filter) {
        entries {
          id
          body
          author {
            id
          }
          post {
            id
            title
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published comments on post", ~m(guest_conn user)a do
      {:ok, post} = db_insert(:post)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"
          {:ok, comment} = CMS.create_comment(:post, post.id, %{body: body}, user)
          acc ++ [comment]
        end)

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "publishedPostComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["post"]["id"] == to_string(post.id)))
      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_comment_id))
    end
  end

  describe "[account published comments on job]" do
    @query """
    query($userId: ID!, $filter: PagedFilter!) {
      publishedJobComments(userId: $userId, filter: $filter) {
        entries {
          id
          body
          author {
            id
          }
          job {
            id
            title
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published comments on job", ~m(guest_conn user)a do
      {:ok, job} = db_insert(:job)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"
          {:ok, comment} = CMS.create_comment(:job, job.id, %{body: body}, user)
          acc ++ [comment]
        end)

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "publishedJobComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["job"]["id"] == to_string(job.id)))
      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_comment_id))
    end
  end

  describe "[account published comments on video]" do
    @query """
    query($userId: ID!, $filter: PagedFilter!) {
      publishedVideoComments(userId: $userId, filter: $filter) {
        entries {
          id
          body
          author {
            id
          }
          video {
            id
            title
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published comments on video", ~m(guest_conn user)a do
      {:ok, video} = db_insert(:video)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"
          {:ok, comment} = CMS.create_comment(:video, video.id, %{body: body}, user)
          acc ++ [comment]
        end)

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "publishedVideoComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["video"]["id"] == to_string(video.id)))
      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_comment_id))
    end
  end

  describe "[account published comments on repo]" do
    @query """
    query($userId: ID!, $filter: PagedFilter!) {
      publishedRepoComments(userId: $userId, filter: $filter) {
        entries {
          id
          body
          author {
            id
          }
          repo {
            id
            title
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get paged published comments on repo", ~m(guest_conn user)a do
      {:ok, repo} = db_insert(:repo)

      pub_comments =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          body = "this is a test comment"
          {:ok, comment} = CMS.create_comment(:repo, repo.id, %{body: body}, user)
          acc ++ [comment]
        end)

      random_comment_id = pub_comments |> Enum.random() |> Map.get(:id) |> to_string

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "publishedRepoComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == @publish_count

      assert results["entries"] |> Enum.all?(&(&1["repo"]["id"] == to_string(repo.id)))
      assert results["entries"] |> Enum.all?(&(&1["author"]["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == random_comment_id))
    end
  end
end
