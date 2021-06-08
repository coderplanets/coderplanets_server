defmodule GroupherServer.Test.Mutation.Comments.RepoComment do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.Model.Repo

  alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community repo)a}
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
    test "write article comment to a exsit repo", ~m(repo user_conn)a do
      comment = "a test comment"
      variables = %{thread: "REPO", id: repo.id, content: comment}

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
    test "login user can reply to a comment", ~m(repo user user_conn)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, "commment", user)
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
         ~m(repo user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, "repo comment", user)
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
         ~m(repo user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, "repo comment", user)
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
    @tag :wip
    test "login user can upvote a exsit repo comment", ~m(repo user guest_conn user_conn)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, "repo comment", user)
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
    @tag :wip
    test "login user can undo upvote a exsit repo comment", ~m(repo user guest_conn user_conn)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, "repo comment", user)
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
    test "login user can emotion to a comment", ~m(repo user user_conn)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, "repo comment", user)
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
    test "login user can undo emotion to a comment", ~m(repo user owner_conn)a do
      {:ok, comment} = CMS.create_article_comment(:repo, repo.id, "repo comment", user)
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
      lockRepoComment(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "can lock a repo's comment", ~m(community repo)a do
      variables = %{id: repo.id, communityId: community.id}
      passport_rules = %{community.raw => %{"repo.lock_comment" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "lockRepoComment")
      assert result["id"] == to_string(repo.id)

      {:ok, repo} = ORM.find(Repo, repo.id)
      assert repo.meta.is_comment_locked
    end

    test "unauth user  fails", ~m(guest_conn community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($id: ID!, $communityId: ID!){
      undoLockRepoComment(id: $id, communityId: $communityId) {
        id
      }
    }
    """

    test "can undo lock a repo's comment", ~m(community repo)a do
      {:ok, _} = CMS.lock_article_comment(:repo, repo.id)
      {:ok, repo} = ORM.find(Repo, repo.id)
      assert repo.meta.is_comment_locked

      variables = %{id: repo.id, communityId: community.id}
      passport_rules = %{community.raw => %{"repo.undo_lock_comment" => true}}
      rule_conn = simu_conn(:user, cms: passport_rules)

      result = rule_conn |> mutation_result(@query, variables, "undoLockRepoComment")
      assert result["id"] == to_string(repo.id)

      {:ok, repo} = ORM.find(Repo, repo.id)
      assert not repo.meta.is_comment_locked
    end

    test "unauth user undo fails", ~m(guest_conn community repo)a do
      variables = %{id: repo.id, communityId: community.id}

      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end
  end
end
