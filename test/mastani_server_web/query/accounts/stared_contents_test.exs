defmodule GroupherServer.Test.Query.Accounts.StaredContents do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  @total_count 20

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, posts} = db_insert_multi(:post, @total_count)
    {:ok, jobs} = db_insert_multi(:job, @total_count)
    {:ok, videos} = db_insert_multi(:video, @total_count)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user posts jobs videos)a}
  end

  describe "[accounts stared posts]" do
    @query """
    query($filter: PagedFilter!) {
      user {
        id
        staredPosts(filter: $filter) {
          entries {
            id
          }
          totalCount
        }
        staredPostsCount
      }
    }
    """
    test "login user can get it's own staredPosts", ~m(user_conn user posts)a do
      Enum.each(posts, fn post ->
        {:ok, _} = CMS.reaction(:post, :star, post.id, user)
      end)

      random_id = posts |> Enum.shuffle() |> List.first() |> Map.get(:id) |> to_string

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "user")
      assert results["staredPosts"] |> Map.get("totalCount") == @total_count
      assert results["staredPostsCount"] == @total_count

      assert results["staredPosts"]
             |> Map.get("entries")
             |> Enum.any?(&(&1["id"] == random_id))
    end

    @query """
    query($userId: ID, $filter: PagedFilter!) {
      staredPosts(userId: $userId,  filter: $filter) {
        entries {
          id
        }
        totalCount
      }
    }
    """
    test "other user can get other user's paged staredPosts",
         ~m(user_conn guest_conn posts)a do
      {:ok, user} = db_insert(:user)

      Enum.each(posts, fn post ->
        {:ok, _} = CMS.reaction(:post, :star, post.id, user)
      end)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "staredPosts")
      results2 = guest_conn |> query_result(@query, variables, "staredPosts")

      assert results["totalCount"] == @total_count
      assert results2["totalCount"] == @total_count
    end
  end

  describe "[accounts stared jobs]" do
    @query """
    query($filter: PagedFilter!) {
      user {
        id
        staredJobs(filter: $filter) {
          entries {
            id
          }
          totalCount
        }
        staredJobsCount
      }
    }
    """
    test "login user can get it's own staredJobs", ~m(user_conn user jobs)a do
      Enum.each(jobs, fn job ->
        {:ok, _} = CMS.reaction(:job, :star, job.id, user)
      end)

      random_id = jobs |> Enum.shuffle() |> List.first() |> Map.get(:id) |> to_string

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "user")
      assert results["staredJobs"] |> Map.get("totalCount") == @total_count
      assert results["staredJobsCount"] == @total_count

      assert results["staredJobs"]
             |> Map.get("entries")
             |> Enum.any?(&(&1["id"] == random_id))
    end

    @query """
    query($userId: ID, $filter: PagedFilter!) {
      staredJobs(userId: $userId,  filter: $filter) {
        entries {
          id
        }
        totalCount
      }
    }
    """
    test "other user can get other user's paged staredJobs",
         ~m(user_conn guest_conn jobs)a do
      {:ok, user} = db_insert(:user)

      Enum.each(jobs, fn job ->
        {:ok, _} = CMS.reaction(:job, :star, job.id, user)
      end)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "staredJobs")
      results2 = guest_conn |> query_result(@query, variables, "staredJobs")

      assert results["totalCount"] == @total_count
      assert results2["totalCount"] == @total_count
    end
  end

  describe "[accounts stared videos]" do
    @query """
    query($filter: PagedFilter!) {
      user {
        id
        staredVideos(filter: $filter) {
          entries {
            id
          }
          totalCount
        }
        staredVideosCount
      }
    }
    """
    test "login user can get it's own staredVideos", ~m(user_conn user videos)a do
      Enum.each(videos, fn video ->
        {:ok, _} = CMS.reaction(:video, :star, video.id, user)
      end)

      random_id = videos |> Enum.shuffle() |> List.first() |> Map.get(:id) |> to_string

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "user")
      assert results["staredVideos"] |> Map.get("totalCount") == @total_count
      assert results["staredVideosCount"] == @total_count

      assert results["staredVideos"]
             |> Map.get("entries")
             |> Enum.any?(&(&1["id"] == random_id))
    end

    @query """
    query($userId: ID, $filter: PagedFilter!) {
      staredVideos(userId: $userId,  filter: $filter) {
        entries {
          id
        }
        totalCount
      }
    }
    """
    test "other user can get other user's paged staredVideos",
         ~m(user_conn guest_conn videos)a do
      {:ok, user} = db_insert(:user)

      Enum.each(videos, fn video ->
        {:ok, _} = CMS.reaction(:video, :star, video.id, user)
      end)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "staredVideos")
      results2 = guest_conn |> query_result(@query, variables, "staredVideos")

      assert results["totalCount"] == @total_count
      assert results2["totalCount"] == @total_count
    end
  end
end
