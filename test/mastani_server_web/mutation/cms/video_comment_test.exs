defmodule MastaniServer.Test.Mutation.VideoComment do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.CMS

  setup do
    {:ok, video} = db_insert(:video)
    {:ok, user} = db_insert(:user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, comment} = CMS.create_comment(:video, video.id, "test comment", user)

    {:ok, ~m(user_conn guest_conn video user comment)a}
  end

  describe "[video comment CURD]" do
    @create_comment_query """
    mutation($thread: CmsThread, $id: ID!, $body: String!) {
      createComment(thread: $thread, id: $id, body: $body) {
        id
        body
      }
    }
    """
    test "login user can create comment to a video", ~m(user_conn video)a do
      variables = %{thread: "VIDEO", id: video.id, body: "this a comment"}
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      {:ok, found} = ORM.find(CMS.VideoComment, created["id"])

      assert created["id"] == to_string(found.id)
    end

    test "guest user create comment fails", ~m(guest_conn video)a do
      variables = %{thread: "VIDEO", id: video.id, body: "this a comment"}

      assert guest_conn
             |> mutation_get_error?(@create_comment_query, variables, ecode(:account_login))
    end

    @delete_comment_query """
    mutation($thread: CmsThread, $id: ID!) {
      deleteComment(thread: $thread, id: $id) {
        id
        body
      }
    }
    """
    @tag :wip
    test "comment owner can delete comment", ~m(user video)a do
      variables = %{thread: "VIDEO", id: video.id, body: "this a comment"}

      user_conn = simu_conn(:user, user)
      created = user_conn |> mutation_result(@create_comment_query, variables, "createComment")

      variables = %{thread: "VIDEO", id: created["id"]}
      deleted = user_conn |> mutation_result(@delete_comment_query, variables, "deleteComment")

      assert deleted["id"] == created["id"]
    end

    @tag :wip
    test "unauth user delete comment fails", ~m(user_conn guest_conn video)a do
      variables = %{thread: "VIDEO", id: video.id, body: "this a comment"}
      {:ok, owner} = db_insert(:user)
      owner_conn = simu_conn(:user, owner)
      created = owner_conn |> mutation_result(@create_comment_query, variables, "createComment")

      variables = %{thread: "VIDEO", id: created["id"]}
      rule_conn = simu_conn(:user, cms: %{"what.ever" => true})

      assert user_conn |> mutation_get_error?(@delete_comment_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@delete_comment_query, variables, ecode(:account_login))

      assert rule_conn |> mutation_get_error?(@delete_comment_query, variables, ecode(:passport))
    end

    @reply_comment_query """
    mutation($thread: CmsThread!, $id: ID!, $body: String!) {
      replyComment(thread: $thread, id: $id, body: $body) {
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
      variables = %{thread: "VIDEO", id: comment.id, body: "this a reply"}
      replied = user_conn |> mutation_result(@reply_comment_query, variables, "replyComment")

      assert replied["replyTo"] |> Map.get("id") == to_string(comment.id)
    end

    test "guest user reply comment fails", ~m(guest_conn comment)a do
      variables = %{thread: "VIDEO", id: comment.id, body: "this a reply"}

      assert guest_conn |> mutation_get_error?(@reply_comment_query, variables)
    end

    test "TODO owner can NOT delete comment when comment has replies" do
    end

    test "TODO owner can NOT edit comment when comment has replies" do
    end

    test "TODO owner can NOT delete comment when comment has created after 3 hours" do
    end
  end

  describe "[video comment reactions]" do
    @like_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      likeComment(thread: $thread, id: $id) {
        id
      }
    }
    """
    test "login user can like a comment", ~m(user_conn comment)a do
      variables = %{thread: "VIDEO_COMMENT", id: comment.id}
      user_conn |> mutation_result(@like_comment_query, variables, "likeComment")

      {:ok, found} = CMS.VideoComment |> ORM.find(comment.id, preload: :likes)

      assert found.likes |> Enum.any?(&(&1.video_comment_id == comment.id))
    end

    @undo_like_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      undoLikeComment(thread: $thread, id: $id) {
        id
      }
    }
    """
    test "login user can undo a like action to comment", ~m(user comment)a do
      variables = %{thread: "VIDEO_COMMENT", id: comment.id}
      user_conn = simu_conn(:user, user)
      user_conn |> mutation_result(@like_comment_query, variables, "likeComment")

      {:ok, found} = CMS.VideoComment |> ORM.find(comment.id, preload: :likes)
      assert found.likes |> Enum.any?(&(&1.video_comment_id == comment.id))

      user_conn |> mutation_result(@undo_like_comment_query, variables, "undoLikeComment")

      {:ok, found} = CMS.VideoComment |> ORM.find(comment.id, preload: :likes)
      assert false == found.likes |> Enum.any?(&(&1.video_comment_id == comment.id))
    end

    @dislike_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      dislikeComment(thread: $thread, id: $id) {
        id
      }
    }
    """
    test "login user can dislike a comment", ~m(user_conn comment)a do
      variables = %{thread: "VIDEO_COMMENT", id: comment.id}
      user_conn |> mutation_result(@dislike_comment_query, variables, "dislikeComment")

      {:ok, found} = CMS.VideoComment |> ORM.find(comment.id, preload: :dislikes)

      assert found.dislikes |> Enum.any?(&(&1.video_comment_id == comment.id))
    end

    @undo_dislike_comment_query """
    mutation($thread: CmsComment!, $id: ID!) {
      undoDislikeComment(thread: $thread, id: $id) {
      id
      }
    }
    """
    test "login user can undo dislike a comment", ~m(user comment)a do
      variables = %{thread: "VIDEO_COMMENT", id: comment.id}
      user_conn = simu_conn(:user, user)
      user_conn |> mutation_result(@dislike_comment_query, variables, "dislikeComment")
      {:ok, found} = CMS.VideoComment |> ORM.find(comment.id, preload: :dislikes)
      assert found.dislikes |> Enum.any?(&(&1.video_comment_id == comment.id))

      user_conn |> mutation_result(@undo_dislike_comment_query, variables, "undoDislikeComment")

      {:ok, found} = CMS.VideoComment |> ORM.find(comment.id, preload: :dislikes)
      assert false == found.dislikes |> Enum.any?(&(&1.video_comment_id == comment.id))
    end

    test "unloged user do/undo like/dislike comment fails", ~m(guest_conn comment)a do
      variables = %{thread: "VIDEO_COMMENT", id: comment.id}

      assert guest_conn |> mutation_get_error?(@like_comment_query, variables)
      assert guest_conn |> mutation_get_error?(@dislike_comment_query, variables)

      assert guest_conn |> mutation_get_error?(@undo_like_comment_query, variables)
      assert guest_conn |> mutation_get_error?(@undo_dislike_comment_query, variables)
    end
  end
end
