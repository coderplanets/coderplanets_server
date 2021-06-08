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
    mutation($thread: Thread!, $id: ID!, $content: String!) {
      createArticleComment(thread: $thread,id: $id, content: $content) {
        id
        bodyHtml
      }
    }
    """
    test "write article comment to a exsit post", ~m(post user_conn)a do
      comment = "a test comment"
      variables = %{thread: "POST", id: post.id, content: comment}

      result =
        user_conn |> mutation_result(@write_comment_query, variables, "createArticleComment")

      assert result["bodyHtml"] == comment
    end

    @reply_comment_query """
    mutation($id: ID!, $content: String!) {
      replyArticleComment(id: $id, content: $content) {
        id
        bodyHtml
      }
    }
    """
    test "login user can reply to a comment", ~m(post user user_conn)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "commment", user)
      variables = %{id: comment.id, content: "reply content"}

      result =
        user_conn
        |> mutation_result(@reply_comment_query, variables, "replyArticleComment")

      assert result["bodyHtml"] == "reply content"
    end

    @update_comment_query """
    mutation($id: ID!, $content: String!) {
      updateArticleComment(id: $id, content: $content) {
        id
        bodyHtml
      }
    }
    """
    test "only owner can update a exsit comment",
         ~m(post user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "post comment", user)
      variables = %{id: comment.id, content: "updated comment"}

      assert user_conn |> mutation_get_error?(@update_comment_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@update_comment_query, variables, ecode(:account_login))

      updated =
        owner_conn |> mutation_result(@update_comment_query, variables, "updateArticleComment")

      assert updated["bodyHtml"] == "updated comment"
    end

    @delete_comment_query """
    mutation($id: ID!) {
      deleteArticleComment(id: $id) {
        id
        isDeleted
      }
    }
    """
    test "only owner can delete a exsit comment",
         ~m(post user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "post comment", user)
      variables = %{id: comment.id}

      assert user_conn |> mutation_get_error?(@delete_comment_query, variables, ecode(:passport))

      assert guest_conn
             |> mutation_get_error?(@delete_comment_query, variables, ecode(:account_login))

      deleted =
        owner_conn |> mutation_result(@delete_comment_query, variables, "deleteArticleComment")

      assert deleted["id"] == to_string(comment.id)
      assert deleted["isDeleted"]
    end
  end

  describe "[article comment upvote]" do
    @upvote_comment_query """
    mutation($id: ID!) {
      upvoteArticleComment(id: $id) {
        id
        upvotesCount
        viewerHasUpvoted
      }
    }
    """

    test "login user can upvote a exsit post comment", ~m(post user guest_conn user_conn)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "post comment", user)
      variables = %{id: comment.id}

      assert guest_conn
             |> mutation_get_error?(@upvote_comment_query, variables, ecode(:account_login))

      result =
        user_conn |> mutation_result(@upvote_comment_query, variables, "upvoteArticleComment")

      assert result["id"] == to_string(comment.id)
      assert result["upvotesCount"] == 1
      assert result["viewerHasUpvoted"]
    end

    @undo_upvote_comment_query """
    mutation($id: ID!) {
      undoUpvoteArticleComment(id: $id) {
        id
        upvotesCount
        viewerHasUpvoted
      }
    }
    """

    test "login user can undo upvote a exsit post comment", ~m(post user guest_conn user_conn)a do
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "post comment", user)
      variables = %{id: comment.id}
      user_conn |> mutation_result(@upvote_comment_query, variables, "upvoteArticleComment")

      assert guest_conn
             |> mutation_get_error?(@undo_upvote_comment_query, variables, ecode(:account_login))

      result =
        user_conn
        |> mutation_result(@undo_upvote_comment_query, variables, "undoUpvoteArticleComment")

      assert result["upvotesCount"] == 0
      assert not result["viewerHasUpvoted"]
    end
  end

  describe "[article comment emotion]" do
    @emotion_comment_query """
    mutation($id: ID!, $emotion: ArticleCommentEmotion!) {
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
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "post comment", user)
      variables = %{id: comment.id, emotion: "BEER"}

      comment =
        user_conn |> mutation_result(@emotion_comment_query, variables, "emotionToComment")

      assert comment |> get_in(["emotions", "beerCount"]) == 1
      assert get_in(comment, ["emotions", "viewerHasBeered"])
    end

    @emotion_comment_query """
    mutation($id: ID!, $emotion: ArticleCommentEmotion!) {
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
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "post comment", user)
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
      {:ok, _} = CMS.lock_article_comment(:post, post.id)
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
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "solution", post_author)

      questioner_conn = simu_conn(:user, post_author)

      variables = %{id: comment.id}

      result = questioner_conn |> mutation_result(@query, variables, "markCommentSolution")

      assert result["isForQuestion"]
      assert result["isSolution"]
    end

    test "other user can not mark a post comment as solution", ~m(guest_conn user_conn post)a do
      {:ok, post} = ORM.find(Post, post.id, preload: [author: :user])
      post_author = post.author.user
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "solution", post_author)

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
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "solution", post_author)
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
      {:ok, comment} = CMS.create_article_comment(:post, post.id, "solution", post_author)

      variables = %{id: comment.id}
      assert user_conn |> mutation_get_error?(@query, variables, ecode(:require_questioner))
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
