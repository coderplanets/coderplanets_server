defmodule GroupherServer.Test.Mutation.Comments.PostComment do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Post

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, post} = CMS.create_article(community, :post, mock_attrs(:post), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community post)a}
  end

  describe "[article comment CURD]" do
    @write_comment_query """
    mutation($thread: Thread!, $id: ID!, $body: String!) {
      createComment(thread: $thread,id: $id, body: $body) {
        id
        bodyHtml
      }
    }
    """
    test "write article comment to a exsit post", ~m(post user_conn)a do
      variables = %{thread: "POST", id: post.id, body: mock_comment()}

      result = user_conn |> mutation_result(@write_comment_query, variables, "createComment")

      assert result["bodyHtml"] |> String.contains?(~s(<p id=))
      assert result["bodyHtml"] |> String.contains?(~s(comment</p>))
    end

    @reply_comment_query """
    mutation($id: ID!, $body: String!) {
      replyComment(id: $id, body: $body) {
        id
        bodyHtml
      }
    }
    """
    test "login user can reply to a comment", ~m(post user user_conn)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      variables = %{id: comment.id, body: mock_comment("reply comment")}

      result = user_conn |> mutation_result(@reply_comment_query, variables, "replyComment")

      assert result["bodyHtml"] |> String.contains?(~s(<p id=))
      assert result["bodyHtml"] |> String.contains?(~s(reply comment</p>))
    end

    @update_comment_query """
    mutation($id: ID!, $body: String!) {
      updateComment(id: $id, body: $body) {
        id
        bodyHtml
      }
    }
    """

    test "only owner can update a exsit comment",
         ~m(post user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      variables = %{id: comment.id, body: mock_comment("updated comment")}

      assert user_conn |> mutation_get_error?(@update_comment_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@update_comment_query, variables, ecode(:account_login))

      result = owner_conn |> mutation_result(@update_comment_query, variables, "updateComment")

      assert result["bodyHtml"] |> String.contains?(~s(<p id=))
      assert result["bodyHtml"] |> String.contains?(~s(updated comment</p>))
    end

    @delete_comment_query """
    mutation($id: ID!) {
      deleteComment(id: $id) {
        id
        isDeleted
      }
    }
    """
    test "only owner can delete a exsit comment",
         ~m(post user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      variables = %{id: comment.id}

      assert user_conn |> mutation_get_error?(@delete_comment_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@delete_comment_query, variables, ecode(:account_login))

      deleted = owner_conn |> mutation_result(@delete_comment_query, variables, "deleteComment")

      assert deleted["id"] == to_string(comment.id)
      assert deleted["isDeleted"]
    end
  end

  describe "[article comment upvote]" do
    @upvote_comment_query """
    mutation($id: ID!) {
      upvoteComment(id: $id) {
        id
        upvotesCount
        viewerHasUpvoted
      }
    }
    """

    test "login user can upvote a exsit post comment", ~m(post user guest_conn user_conn)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      variables = %{id: comment.id}

      assert guest_conn
             |> mutation_get_error?(@upvote_comment_query, variables, ecode(:account_login))

      result = user_conn |> mutation_result(@upvote_comment_query, variables, "upvoteComment")

      assert result["id"] == to_string(comment.id)
      assert result["upvotesCount"] == 1
      assert result["viewerHasUpvoted"]
    end

    @undo_upvote_comment_query """
    mutation($id: ID!) {
      undoUpvoteComment(id: $id) {
        id
        upvotesCount
        viewerHasUpvoted
      }
    }
    """

    test "login user can undo upvote a exsit post comment", ~m(post user guest_conn user_conn)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      variables = %{id: comment.id}
      user_conn |> mutation_result(@upvote_comment_query, variables, "upvoteComment")

      assert guest_conn
             |> mutation_get_error?(@undo_upvote_comment_query, variables, ecode(:account_login))

      result =
        user_conn
        |> mutation_result(@undo_upvote_comment_query, variables, "undoUpvoteComment")

      assert result["upvotesCount"] == 0
      assert not result["viewerHasUpvoted"]
    end
  end

  describe "[article comment emotion]" do
    @emotion_comment_query """
    mutation($id: ID!, $emotion: CommentEmotion!) {
      emotionToComment(id: $id, emotion: $emotion) {
        id
        emotions {
          beerCount
          viewerHasBeered
          latestBeerUsers {
            login
            nickname
          }
        }
      }
    }
    """
    test "login user can emotion to a comment", ~m(post user user_conn)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      variables = %{id: comment.id, emotion: "BEER"}

      comment =
        user_conn |> mutation_result(@emotion_comment_query, variables, "emotionToComment")

      assert comment |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(comment, ["emotions", "viewerHasBeered"])
    end

    @emotion_comment_query """
    mutation($id: ID!, $emotion: CommentEmotion!) {
      undoEmotionToComment(id: $id, emotion: $emotion) {
        id
        emotions {
          beerCount
          viewerHasBeered
          latestBeerUsers {
            login
            nickname
          }
        }
      }
    }
    """
    test "login user can undo emotion to a comment", ~m(post user owner_conn)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.emotion_to_comment(comment.id, :beer, user)

      variables = %{id: comment.id, emotion: "BEER"}

      comment =
        owner_conn |> mutation_result(@emotion_comment_query, variables, "undoEmotionToComment")

      assert comment |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(comment, ["emotions", "viewerHasBeered"])
    end
  end

  describe "[article comment lock/unlock]" do
    @query """
    mutation($id: ID!, $communityId: ID!){
      lockPostComment(id: $id, communityId: $communityId) {
        id
        title
      }
    }
    """

    test "can lock a post's comment", ~m(community post)a do
      variables = %{id: post.id, communityId: community.id}
      passport_rules = %{community.raw => %{"post.lock_comment" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "lockPostComment")
      assert result["id"] == to_string(post.id)

      {:ok, post} = ORM.find(Post, post.id)
      assert post.meta.is_comment_locked
    end

    test "unauth user  fails", ~m(guest_conn community post)a do
      variables = %{id: post.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoLockPostComment(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "can undo lock a post's comment", ~m(community post)a do
      {:ok, _} = CMS.lock_article_comments(:post, post.id)
      {:ok, post} = ORM.find(Post, post.id)
      assert post.meta.is_comment_locked

      variables = %{id: post.id, communityId: community.id}
      passport_rules = %{community.raw => %{"post.undo_lock_comment" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "undoLockPostComment")
      assert result["id"] == to_string(post.id)

      {:ok, post} = ORM.find(Post, post.id)
      assert not post.meta.is_comment_locked
    end

    test "unauth user undo fails", ~m(guest_conn community post)a do
      variables = %{id: post.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end

  describe "[article comment pin/unPin]" do
    @query """
    mutation($id: ID!){
      pinComment(id: $id) {
        id
        isPinned
      }
    }
    """

    test "can pin a post's comment", ~m(owner_conn post user)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)

      variables = %{id: comment.id}
      result = owner_conn |> mutation_result(@query, variables, "pinComment")

      assert result["id"] == to_string(comment.id)
      assert result["isPinned"]
    end

    test "unauth user fails.", ~m(guest_conn post user)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      variables = %{id: comment.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!){
      undoPinComment(id: $id) {
        id
        isPinned
      }
    }
    """

    test "can undo pin a post's comment", ~m(owner_conn post user)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.pin_comment(comment.id)

      variables = %{id: comment.id}
      result = owner_conn |> mutation_result(@query, variables, "undoPinComment")

      assert result["id"] == to_string(comment.id)
      assert not result["isPinned"]
    end

    test "unauth user undo fails.", ~m(guest_conn post user)a do
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), user)
      {:ok, _} = CMS.pin_comment(comment.id)
      variables = %{id: comment.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end

  describe "[post only: article comment solution]" do
    @query """
    mutation($id: ID!) {
      markCommentSolution(id: $id) {
        id
        isForQuestion
        isSolution
      }
    }
    """

    test "questioner can mark a post comment as solution", ~m(post)a do
      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), post_author)

      questioner_conn = simu_conn(:user, post_author)

      variables = %{id: comment.id}

      result = questioner_conn |> mutation_result(@query, variables, "markCommentSolution")

      assert result["isForQuestion"]
      assert result["isSolution"]
    end

    test "other user can not mark a post comment as solution", ~m(guest_conn user_conn post)a do
      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), post_author)

      variables = %{id: comment.id}
      assert user_conn |> mutation_get_error?(@query, variables, ecode(:require_questioner))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!) {
      undoMarkCommentSolution(id: $id) {
        id
        isForQuestion
        isSolution
      }
    }
    """

    test "questioner can undo mark a post comment as solution", ~m(post)a do
      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), post_author)
      {:ok, comment} = CMS.mark_comment_solution(comment.id, post_author)

      questioner_conn = simu_conn(:user, post_author)

      variables = %{id: comment.id}
      result = questioner_conn |> mutation_result(@query, variables, "undoMarkCommentSolution")

      assert result["isForQuestion"]
      assert not result["isSolution"]
    end

    test "other user can not undo mark a post comment as solution",
         ~m(guest_conn user_conn post)a do
      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user
      {:ok, comment} = CMS.create_comment(:post, post.id, mock_comment(), post_author)

      variables = %{id: comment.id}
      assert user_conn |> mutation_get_error?(@query, variables, ecode(:require_questioner))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
