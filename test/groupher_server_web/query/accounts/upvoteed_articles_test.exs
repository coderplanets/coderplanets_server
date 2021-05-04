defmodule GroupherServer.Test.Query.Accounts.UpvotedArticles do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  @total_count 20

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, posts} = db_insert_multi(:post, @total_count)
    {:ok, jobs} = db_insert_multi(:job, @total_count)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user posts jobs)a}
  end

  describe "[accounts upvoted posts]" do
    @query """
    query($filter: UpvotedArticlesFilter!) {
      pagedUpvotedArticles(filter: $filter) {
        entries {
          id
          title
          thread
        }
        totalCount
      }
    }
    """
    @tag :wip2
    test "both login and unlogin user can get one's paged upvoteded posts",
         ~m(user_conn guest_conn posts)a do
      {:ok, user} = db_insert(:user)

      Enum.each(posts, fn post ->
        {:ok, _} = CMS.upvote_article(:post, post.id, user)
      end)

      variables = %{
        userId: user.id,
        filter: %{user_id: user.id, thread: "POST", page: 1, size: 20}
      }

      results = user_conn |> query_result(@query, variables, "pagedUpvotedArticles")
      results2 = guest_conn |> query_result(@query, variables, "pagedUpvotedArticles")

      assert results["totalCount"] == @total_count
      assert results2["totalCount"] == @total_count
    end

    @tag :wip2
    test "if no thread filter will get alll paged upvoteded articles",
         ~m(guest_conn posts jobs)a do
      {:ok, user} = db_insert(:user)

      Enum.each(posts, fn post ->
        {:ok, _} = CMS.upvote_article(:post, post.id, user)
      end)

      Enum.each(jobs, fn job ->
        {:ok, _} = CMS.upvote_article(:job, job.id, user)
      end)

      variables = %{
        userId: user.id,
        filter: %{user_id: user.id, page: 1, size: 20}
      }

      results = guest_conn |> query_result(@query, variables, "pagedUpvotedArticles")

      assert results["totalCount"] == @total_count + @total_count
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
end
