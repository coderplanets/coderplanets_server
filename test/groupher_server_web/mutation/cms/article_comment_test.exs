defmodule GroupherServer.Test.Mutation.ArticleComment do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, post} = db_insert(:post)
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)
    owner_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn user guest_conn owner_conn community post)a}
  end

  describe "[create article comment]" do
    @write_comment_query """
    mutation($thread: CmsThread!, $id: ID!, $content: String!) {
      createArticleComment(thread: $thread,id: $id, content: $content) {
        id
        bodyHtml
      }
    }
    """
    @tag :wip2
    test "write article comment to a exsit post", ~m(post user_conn)a do
      comment = "a test comment"
      variables = %{thread: "POST", id: post.id, content: comment}

      result =
        user_conn |> mutation_result(@write_comment_query, variables, "createArticleComment")

      assert result["bodyHtml"] == comment
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
      deleteComment(id: $id) {
        id
      }
    }
    """
    test "delete a comment", ~m(post user_conn community)a do
      variables1 = %{
        community: community.raw,
        thread: "POST",
        id: post.id,
        body: "a test comment"
      }

      created = user_conn |> mutation_result(@create_comment_query, variables1, "createComment")
      assert created["body"] == variables1.body

      variables2 = %{id: created["id"]}

      deleted = user_conn |> mutation_result(@delete_comment_query, variables2, "deleteComment")

      assert deleted["id"] == created["id"]

      assert {:error, _} = ORM.find(CMS.PostComment, deleted["id"])
    end
  end
end
