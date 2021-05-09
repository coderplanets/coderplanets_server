defmodule GroupherServer.Test.Mutation.Comments.JobComment do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, job} = db_insert(:job)
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community job)a}
  end

  describe "[article comment CURD]" do
    @write_comment_query """
    mutation($thread: CmsThread!, $id: ID!, $content: String!) {
      createArticleComment(thread: $thread,id: $id, content: $content) {
        id
        bodyHtml
      }
    }
    """
    @tag :wip2
    test "write article comment to a exsit job", ~m(job user_conn)a do
      comment = "a test comment"
      variables = %{thread: "JOB", id: job.id, content: comment}

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
    @tag :wip2
    test "login user can reply to a comment", ~m(job user user_conn)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "commment", user)
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
    @tag :wip2
    test "only owner can update a exsit comment",
         ~m(job user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "job comment", user)
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
    @tag :wip2
    test "only owner can delete a exsit comment",
         ~m(job user guest_conn user_conn owner_conn)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "job comment", user)
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
    @tag :wip2
    test "login user can emotion to a comment", ~m(job user user_conn)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "job comment", user)
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
    @tag :wip2
    test "login user can undo emotion to a comment", ~m(job user owner_conn)a do
      {:ok, comment} = CMS.create_article_comment(:job, job.id, "job comment", user)
      {:ok, _} = CMS.emotion_to_comment(comment.id, :beer, user)

      variables = %{id: comment.id, emotion: "BEER"}

      comment =
        owner_conn |> mutation_result(@emotion_comment_query, variables, "undoEmotionToComment")

      assert comment |> get_in(["emotions", "beerCount"]) == 0
      assert not get_in(comment, ["emotions", "viewerHasBeered"])
    end
  end
end
