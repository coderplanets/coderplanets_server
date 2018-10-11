defmodule MastaniServer.Test.Query.ReactionUsers do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, job} = db_insert(:job)
    {:ok, video} = db_insert(:video)
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn user user2 post job video)a}
  end

  @query """
  query(
    $id: ID!
    $thread: ReactThread
    $action: ReactAction!
    $filter: PagedFilter!
  ) {
    reactionUsers(id: $id, thread: $thread, action: $action, filter: $filter) {
      entries {
        id
        avatar
        nickname
      }
      totalPages
      totalCount
      pageSize
      pageNumber
    }
  }
  """
  describe "[favrotes users]" do
    test "guest can get favroted user list after favrote to a post",
         ~m(guest_conn post user user2)a do
      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user)
      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user2)

      variables = %{id: post.id, thread: "POST", action: "FAVORITE", filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "reactionUsers")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user2.id)))
    end

    test "guest can get favroted user list after favrote to a job",
         ~m(guest_conn job user user2)a do
      {:ok, _} = CMS.reaction(:job, :favorite, job.id, user)
      {:ok, _} = CMS.reaction(:job, :favorite, job.id, user2)

      variables = %{id: job.id, thread: "JOB", action: "FAVORITE", filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "reactionUsers")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user2.id)))
    end

    test "guest can get favroted user list after favrote to a video",
         ~m(guest_conn video user user2)a do
      {:ok, _} = CMS.reaction(:video, :favorite, video.id, user)
      {:ok, _} = CMS.reaction(:video, :favorite, video.id, user2)

      variables = %{
        id: video.id,
        thread: "VIDEO",
        action: "FAVORITE",
        filter: %{page: 1, size: 20}
      }

      results = guest_conn |> query_result(@query, variables, "reactionUsers")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user2.id)))
    end
  end

  describe "[stars users]" do
    test "guest can get stared user list after star to a post", ~m(guest_conn post user user2)a do
      {:ok, _} = CMS.reaction(:post, :star, post.id, user)
      {:ok, _} = CMS.reaction(:post, :star, post.id, user2)

      variables = %{id: post.id, thread: "POST", action: "STAR", filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "reactionUsers")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user2.id)))
    end

    test "guest can get stared user list after star to a video",
         ~m(guest_conn video user user2)a do
      {:ok, _} = CMS.reaction(:video, :star, video.id, user)
      {:ok, _} = CMS.reaction(:video, :star, video.id, user2)

      variables = %{id: video.id, thread: "VIDEO", action: "STAR", filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "reactionUsers")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 2
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user2.id)))
    end
  end
end
