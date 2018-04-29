defmodule MastaniServer.Test.Mutation.PostCommentTest do
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.ConnSimulator
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  alias MastaniServer.{CMS, Accounts}
  alias Helper.ORM

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)

    # {:ok, user2} = db_insert(:user)
    # {:ok, post2} = db_insert(:post)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, comment} =
      CMS.create_comment(:post, :comment, post.id, %Accounts.User{id: user.id}, "test comment")

    {:ok, ~m(user_conn guest_conn post user comment)a}
  end

  describe "[post comment CURD]" do
    @create_comment_query """
    mutation($part: CmsPart!, $id: ID!, $body: String!) {
      createComment(part: $part, id: $id, body: $body) {
        id
        body
      }
    }
    """
    test "login user can create comment to a post", ~m(user_conn post)a do
      variables = %{part: "POST", id: post.id, body: "this a comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      {:ok, found} = ORM.find(CMS.PostComment, created["id"])

      assert created["id"] == to_string(found.id)
    end

    test "guest user create comment fails", ~m(guest_conn post)a do
      variables = %{part: "POST", id: post.id, body: "this a comment"}

      assert guest_conn |> mutation_get_error?(@create_comment_query, variables)
    end

    @reply_comment_query """
    mutation($part: CmsPart!, $id: ID!, $body: String!) {
      replyComment(part: $part, id: $id, body: $body) {
        id
        body
        replyTo {
          id
          body
        }
      }
    }
    """
    test "login user can reply to a exsit comment", ~m(user_conn comment)a do
      variables = %{part: "POST", id: comment.id, body: "this a reply"}
      replied = user_conn |> mutation_result(@reply_comment_query, variables, "replyComment")

      assert replied["replyTo"] |> Map.get("id") == to_string(comment.id)
    end

    test "guest user reply comment fails", ~m(guest_conn comment)a do
      variables = %{part: "POST", id: comment.id, body: "this a reply"}

      assert guest_conn |> mutation_get_error?(@reply_comment_query, variables)
    end

    test "TODO owner can NOT delete comment when comment has replies" do
    end

    test "TODO owner can NOT edit comment when comment has replies" do
    end

    test "TODO owner can NOT delete comment when comment has created after 3 hours" do
    end
  end

  describe "[post comment reactions]" do
    @like_comment_query """
    mutation($part: CmsComment!, $id: ID!) {
      likeComment(part: $part, id: $id) {
        id
      }
    }
    """
    test "login user can like a comment", ~m(user_conn comment)a do
      variables = %{part: "POST_COMMENT", id: comment.id}
      user_conn |> mutation_result(@like_comment_query, variables, "likeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :likes)

      assert found.likes |> Enum.any?(&(&1.post_comment_id == comment.id))
    end

    @undo_like_comment_query """
    mutation($part: CmsComment!, $id: ID!) {
      undoLikeComment(part: $part, id: $id) {
        id
      }
    }
    """
    test "login user can undo a like action to comment", ~m(user comment)a do
      variables = %{part: "POST_COMMENT", id: comment.id}
      user_conn = simu_conn(:user, user)
      user_conn |> mutation_result(@like_comment_query, variables, "likeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :likes)
      assert found.likes |> Enum.any?(&(&1.post_comment_id == comment.id))

      user_conn |> mutation_result(@undo_like_comment_query, variables, "undoLikeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :likes)
      assert false == found.likes |> Enum.any?(&(&1.post_comment_id == comment.id))
    end

    @dislike_comment_query """
    mutation($part: CmsComment!, $id: ID!) {
      dislikeComment(part: $part, id: $id) {
        id
      }
    }
    """
    test "login user can dislike a comment", ~m(user_conn comment)a do
      variables = %{part: "POST_COMMENT", id: comment.id}
      user_conn |> mutation_result(@dislike_comment_query, variables, "dislikeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :dislikes)

      assert found.dislikes |> Enum.any?(&(&1.post_comment_id == comment.id))
    end

    @undo_dislike_comment_query """
    mutation($part: CmsComment!, $id: ID!) {
      undoDislikeComment(part: $part, id: $id) {
      id
      }
    }
    """
    test "login user can undo dislike a comment", ~m(user comment)a do
      variables = %{part: "POST_COMMENT", id: comment.id}
      user_conn = simu_conn(:user, user)
      user_conn |> mutation_result(@dislike_comment_query, variables, "dislikeComment")
      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :dislikes)
      assert found.dislikes |> Enum.any?(&(&1.post_comment_id == comment.id))

      user_conn |> mutation_result(@undo_dislike_comment_query, variables, "undoDislikeComment")

      {:ok, found} = CMS.PostComment |> ORM.find(comment.id, preload: :dislikes)
      assert false == found.dislikes |> Enum.any?(&(&1.post_comment_id == comment.id))
    end

    test "unloged user do/undo like/dislike comment fails", ~m(guest_conn comment)a do
      variables = %{part: "POST_COMMENT", id: comment.id}

      assert guest_conn |> mutation_get_error?(@like_comment_query, variables)
      assert guest_conn |> mutation_get_error?(@dislike_comment_query, variables)

      assert guest_conn |> mutation_get_error?(@undo_like_comment_query, variables)
      assert guest_conn |> mutation_get_error?(@undo_dislike_comment_query, variables)
    end
  end
end
