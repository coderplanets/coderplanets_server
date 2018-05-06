defmodule MastaniServer.Test.Query.PostCommentTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.ConnSimulator
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  alias MastaniServer.{CMS, Accounts}

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
    query comments($id: ID!, $filter: PagedFilter!) {
      comments(id: $id, filter: $filter) {
        entries {
          id
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "guest user can get a paged comment", ~m(guest_conn post user)a do
      content = "test comment"

      Enum.reduce(1..30, [], fn _, acc ->
        {:ok, value} = CMS.create_comment(:post, post.id, %Accounts.User{id: user.id}, content)

        acc ++ [value]
      end)

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "comments")

      assert results |> is_valid_pagination?
      assert results["totalCount"] == 30
    end

    @query """
    query comments($id: ID!, $filter: PagedFilter!) {
      comments(id: $id, filter: $filter) {
        entries {
          id
          viewerHasLiked
        }
      }
    }
    """
    test "login user can get hasLiked feedBack", ~m(user_conn post user)a do
      body = "test comment"

      {:ok, comment} = CMS.create_comment(:post, post.id, %Accounts.User{id: user.id}, body)

      {:ok, _like} = CMS.like_comment(:post_comment, comment.id, %Accounts.User{id: user.id})

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = user_conn |> query_result(@query, variables, "comments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      assert found["viewerHasLiked"] == false

      own_like_conn = simu_conn(:user, user)
      results = own_like_conn |> query_result(@query, variables, "comments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      assert found["viewerHasLiked"] == true
    end

    @query """
    query comments($id: ID!, $filter: PagedFilter!) {
      comments(id: $id, filter: $filter) {
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

      {:ok, comment} = CMS.create_comment(:post, post.id, %Accounts.User{id: user.id}, body)

      {:ok, _like} = CMS.like_comment(:post_comment, comment.id, %Accounts.User{id: user.id})

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "comments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      author = found |> Map.get("author")

      assert author["id"] == to_string(user.id)
      assert found["likesCount"] == 1

      assert found["likes"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
    end

    @query """
    query comments($id: ID!, $filter: PagedFilter!) {
      comments(id: $id, filter: $filter) {
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

      {:ok, comment} = CMS.create_comment(:post, post.id, %Accounts.User{id: user.id}, body)

      {:ok, _like} = CMS.dislike_comment(:post_comment, comment.id, %Accounts.User{id: user.id})

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "comments")

      found =
        results["entries"] |> Enum.filter(&(&1["id"] == to_string(comment.id))) |> List.first()

      author = found |> Map.get("author")

      assert author["id"] == to_string(user.id)
      assert found["dislikesCount"] == 1

      assert found["dislikes"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
    end

    @query """
    query comments($id: ID!, $filter: PagedFilter!) {
      comments(id: $id, filter: $filter) {
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

      {:ok, comment} = CMS.create_comment(:post, post.id, %Accounts.User{id: user.id}, body)

      {:ok, reply} =
        CMS.reply_comment(:post, comment.id, %Accounts.User{id: user.id}, "reply body")

      variables = %{id: post.id, filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "comments")

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
