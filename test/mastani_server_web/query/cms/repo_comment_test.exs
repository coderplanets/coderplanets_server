defmodule MastaniServer.Test.Query.RepoComment do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, repo} = db_insert(:repo)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn repo user)a}
  end

  # TODO: user can get specific user's replies :list_replies
  describe "[repo comment]" do
    @query """
    query($thread: CmsThread, $id: ID!, $filter: CommentsFilter!) {
      pagedComments(thread: $thread, id: $id, filter: $filter) {
        entries {
          id
          body
          likesCount
          dislikesCount
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    @tag :wip
    test "guest user can get a paged comment", ~m(guest_conn repo user)a do
      body = "test comment"

      Enum.reduce(1..30, [], fn _, acc ->
        {:ok, value} = CMS.create_comment(:repo, repo.id, body, user)

        acc ++ [value]
      end)

      variables = %{thread: "REPO", id: repo.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 30
    end

    @tag :wip2
    test "MOST_LIKES filter should work", ~m(guest_conn repo user)a do
      body = "test comment"

      comments =
        Enum.reduce(1..10, [], fn _, acc ->
          {:ok, value} = CMS.create_comment(:repo, repo.id, body, user)

          acc ++ [value]
        end)

      [comment_1, _comment_2, comment_3, _comment_last] = comments |> firstn_and_last(3)

      {:ok, [user_1, user_2, user_3, user_4, user_5]} = db_insert_multi(:user, 5)

      # comment_3 is most likes
      {:ok, _} = CMS.like_comment(:repo_comment, comment_3.id, user_1)
      {:ok, _} = CMS.like_comment(:repo_comment, comment_3.id, user_2)
      {:ok, _} = CMS.like_comment(:repo_comment, comment_3.id, user_3)
      {:ok, _} = CMS.like_comment(:repo_comment, comment_3.id, user_4)
      {:ok, _} = CMS.like_comment(:repo_comment, comment_3.id, user_5)

      {:ok, _} = CMS.like_comment(:repo_comment, comment_1.id, user_1)
      {:ok, _} = CMS.like_comment(:repo_comment, comment_1.id, user_2)
      {:ok, _} = CMS.like_comment(:repo_comment, comment_1.id, user_3)
      {:ok, _} = CMS.like_comment(:repo_comment, comment_1.id, user_4)

      variables = %{
        thread: "REPO",
        id: repo.id,
        filter: %{page: 1, size: 10, sort: "MOST_LIKES"}
      }

      results = guest_conn |> query_result(@query, variables, "pagedComments")

      entries = results["entries"]

      assert entries |> Enum.at(0) |> Map.get("id") == to_string(comment_3.id)
      assert entries |> Enum.at(0) |> Map.get("likesCount") == 5

      assert entries |> Enum.at(1) |> Map.get("id") == to_string(comment_1.id)
      assert entries |> Enum.at(1) |> Map.get("likesCount") == 4
    end

    @tag :wip
    test "MOST_DISLIKES filter should work", ~m(guest_conn repo user)a do
      body = "test comment"

      comments =
        Enum.reduce(1..10, [], fn _, acc ->
          {:ok, value} = CMS.create_comment(:repo, repo.id, body, user)

          acc ++ [value]
        end)

      [comment_1, _comment_2, comment_3, _comment_last] = comments |> firstn_and_last(3)
      {:ok, [user_1, user_2, user_3, user_4, user_5]} = db_insert_multi(:user, 5)

      # comment_3 is most likes
      {:ok, _} = CMS.dislike_comment(:repo_comment, comment_3.id, user_1)
      {:ok, _} = CMS.dislike_comment(:repo_comment, comment_3.id, user_2)
      {:ok, _} = CMS.dislike_comment(:repo_comment, comment_3.id, user_3)
      {:ok, _} = CMS.dislike_comment(:repo_comment, comment_3.id, user_4)
      {:ok, _} = CMS.dislike_comment(:repo_comment, comment_3.id, user_5)

      {:ok, _} = CMS.dislike_comment(:repo_comment, comment_1.id, user_1)
      {:ok, _} = CMS.dislike_comment(:repo_comment, comment_1.id, user_2)
      {:ok, _} = CMS.dislike_comment(:repo_comment, comment_1.id, user_3)
      {:ok, _} = CMS.dislike_comment(:repo_comment, comment_1.id, user_4)

      variables = %{
        thread: "REPO",
        id: repo.id,
        filter: %{page: 1, size: 10, sort: "MOST_DISLIKES"}
      }

      results = guest_conn |> query_result(@query, variables, "pagedComments")
      entries = results["entries"]

      assert entries |> Enum.at(0) |> Map.get("id") == to_string(comment_3.id)
      assert entries |> Enum.at(0) |> Map.get("dislikesCount") == 5

      assert entries |> Enum.at(1) |> Map.get("id") == to_string(comment_1.id)
      assert entries |> Enum.at(1) |> Map.get("dislikesCount") == 4
    end

    @query """
    query($thread: CmsThread, $id: ID!, $filter: CommentsFilter!) {
      pagedComments(thread: $thread, id: $id, filter: $filter) {
        entries {
          id
          viewerHasLiked
        }
      }
    }
    """
    @tag :wip
    test "login user can get hasLiked feedBack", ~m(user_conn repo user)a do
      body = "test comment"

      {:ok, comment} = CMS.create_comment(:repo, repo.id, body, user)

      {:ok, _like} = CMS.like_comment(:repo_comment, comment.id, user)

      variables = %{thread: "REPO", id: repo.id, filter: %{page: 1, size: 10}}
      results = user_conn |> query_result(@query, variables, "pagedComments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      assert found["viewerHasLiked"] == false

      own_like_conn = simu_conn(:user, user)
      results = own_like_conn |> query_result(@query, variables, "pagedComments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      assert found["viewerHasLiked"] == true
    end

    @query """
    query($thread: CmsThread, $id: ID!, $filter: PagedFilter!) {
      pagedComments(thread: $thread, id: $id, filter: $filter) {
        entries {
          id
          body
          replyTo {
            id
            body
          }
          repliesCount
          replies {
            id
            body
          }
        }
      }
    }
    """
    @tag :wip
    test "guest user can get replies info", ~m(guest_conn repo user)a do
      body = "test comment"
      {:ok, comment} = CMS.create_comment(:repo, repo.id, body, user)

      {:ok, reply} = CMS.reply_comment(:repo, comment.id, "reply body", user)

      variables = %{thread: "REPO", id: repo.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      found_reply =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(reply.id))) |> List.first()

      assert found["repliesCount"] == 1
      assert found["replies"] |> Enum.any?(&(&1["id"] == to_string(reply.id)))
      assert found["replyTo"] == nil
      assert found_reply["replyTo"] |> Map.get("id") == to_string(comment.id)
    end
  end
end
