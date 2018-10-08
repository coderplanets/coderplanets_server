defmodule MastaniServer.Test.Query.PostComment do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn post user)a}
  end

  # TODO: user can get specific user's replies :list_replies
  # TODO: filter comment by time / like / reply
  describe "[post comment]" do
    @query """
    query($id: ID!, $filter: CommentsFilter!) {
      pagedComments(id: $id, filter: $filter) {
        entries {
          id
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
    test "guest user can get a paged comment", ~m(guest_conn post user)a do
      body = "test comment"

      Enum.reduce(1..30, [], fn _, acc ->
        {:ok, value} = CMS.create_comment(:post, post.id, body, user)

        acc ++ [value]
      end)

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 30
    end

    test "MOST_LIKES filter should work", ~m(guest_conn post user)a do
      body = "test comment"

      comments =
        Enum.reduce(1..10, [], fn _, acc ->
          {:ok, value} = CMS.create_comment(:post, post.id, body, user)

          acc ++ [value]
        end)

      [comment_1, _comment_2, comment_3, _comment_last] = comments |> firstn_and_last(3)
      {:ok, [user_1, user_2, user_3, user_4, user_5]} = db_insert_multi(:user, 5)

      # comment_3 is most likes
      {:ok, _} = CMS.like_comment(:post_comment, comment_3.id, user_1)
      {:ok, _} = CMS.like_comment(:post_comment, comment_3.id, user_2)
      {:ok, _} = CMS.like_comment(:post_comment, comment_3.id, user_3)
      {:ok, _} = CMS.like_comment(:post_comment, comment_3.id, user_4)
      {:ok, _} = CMS.like_comment(:post_comment, comment_3.id, user_5)

      {:ok, _} = CMS.like_comment(:post_comment, comment_1.id, user_1)
      {:ok, _} = CMS.like_comment(:post_comment, comment_1.id, user_2)
      {:ok, _} = CMS.like_comment(:post_comment, comment_1.id, user_3)
      {:ok, _} = CMS.like_comment(:post_comment, comment_1.id, user_4)

      variables = %{id: post.id, filter: %{page: 1, size: 10, sort: "MOST_LIKES"}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")
      entries = results["entries"]

      assert entries |> Enum.at(0) |> Map.get("id") == to_string(comment_3.id)
      assert entries |> Enum.at(0) |> Map.get("likesCount") == 5

      assert entries |> Enum.at(1) |> Map.get("id") == to_string(comment_1.id)
      assert entries |> Enum.at(1) |> Map.get("likesCount") == 4
    end

    test "MOST_DISLIKES filter should work", ~m(guest_conn post user)a do
      body = "test comment"

      comments =
        Enum.reduce(1..10, [], fn _, acc ->
          {:ok, value} = CMS.create_comment(:post, post.id, body, user)

          acc ++ [value]
        end)

      [comment_1, _comment_2, comment_3, _comment_last] = comments |> firstn_and_last(3)
      {:ok, [user_1, user_2, user_3, user_4, user_5]} = db_insert_multi(:user, 5)

      # comment_3 is most likes
      {:ok, _} = CMS.dislike_comment(:post_comment, comment_3.id, user_1)
      {:ok, _} = CMS.dislike_comment(:post_comment, comment_3.id, user_2)
      {:ok, _} = CMS.dislike_comment(:post_comment, comment_3.id, user_3)
      {:ok, _} = CMS.dislike_comment(:post_comment, comment_3.id, user_4)
      {:ok, _} = CMS.dislike_comment(:post_comment, comment_3.id, user_5)

      {:ok, _} = CMS.dislike_comment(:post_comment, comment_1.id, user_1)
      {:ok, _} = CMS.dislike_comment(:post_comment, comment_1.id, user_2)
      {:ok, _} = CMS.dislike_comment(:post_comment, comment_1.id, user_3)
      {:ok, _} = CMS.dislike_comment(:post_comment, comment_1.id, user_4)

      variables = %{id: post.id, filter: %{page: 1, size: 10, sort: "MOST_DISLIKES"}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")
      entries = results["entries"]

      assert entries |> Enum.at(0) |> Map.get("id") == to_string(comment_3.id)
      assert entries |> Enum.at(0) |> Map.get("dislikesCount") == 5

      assert entries |> Enum.at(1) |> Map.get("id") == to_string(comment_1.id)
      assert entries |> Enum.at(1) |> Map.get("dislikesCount") == 4
    end

    @query """
    query($id: ID!, $filter: CommentsFilter!) {
      pagedComments(id: $id, filter: $filter) {
        entries {
          id
          viewerHasLiked
        }
      }
    }
    """
    test "login user can get hasLiked feedBack", ~m(user_conn post user)a do
      body = "test comment"

      {:ok, comment} = CMS.create_comment(:post, post.id, body, user)

      {:ok, _like} = CMS.like_comment(:post_comment, comment.id, user)

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
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
    query($id: ID!, $filter: PagedFilter!) {
      pagedComments(id: $id, filter: $filter) {
        entries {
          id
          body
          author {
            id
            nickname
          }
          likesCount
          likes {
            id
            nickname
          }
        }
      }
    }
    """
    test "guest user can get likes info", ~m(guest_conn post user)a do
      body = "test comment"

      {:ok, comment} = CMS.create_comment(:post, post.id, body, user)

      {:ok, _like} = CMS.like_comment(:post_comment, comment.id, user)

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      author = found |> Map.get("author")

      assert author["id"] == to_string(user.id)
      assert found["likesCount"] == 1

      assert found["likes"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
    end

    @query """
    query($id: ID!, $filter: PagedFilter!) {
      pagedComments(id: $id, filter: $filter) {
        entries {
          id
          body
          author {
            id
            nickname
          }
          dislikesCount
          dislikes {
            id
            nickname
          }
        }
      }
    }
    """
    test "guest user can get dislikes info", ~m(guest_conn post user)a do
      body = "test comment"

      {:ok, comment} = CMS.create_comment(:post, post.id, body, user)

      {:ok, _like} = CMS.dislike_comment(:post_comment, comment.id, user)

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      author = found |> Map.get("author")

      assert author["id"] == to_string(user.id)
      assert found["dislikesCount"] == 1

      assert found["dislikes"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
    end

    @query """
    query($id: ID!, $filter: PagedFilter!) {
      pagedComments(id: $id, filter: $filter) {
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
    test "guest user can get replies info", ~m(guest_conn post user)a do
      body = "test comment"

      {:ok, comment} = CMS.create_comment(:post, post.id, body, user)

      {:ok, reply} = CMS.reply_comment(:post, comment.id, "reply body", user)

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedComments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      found_reply =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(reply.id))) |> List.first()

      # author = found |> Map.get("author")
      assert found["repliesCount"] == 1
      assert found["replies"] |> Enum.any?(&(&1["id"] == to_string(reply.id)))
      assert found["replyTo"] == nil
      assert found_reply["replyTo"] |> Map.get("id") == to_string(comment.id)
    end
  end
end
