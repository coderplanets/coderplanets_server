defmodule GroupherServer.Test.ArticleUpvote do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias CMS.{ArticleUpvote}

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 community post_attrs)a}
  end

  describe "[cms post upvote]" do
    @tag :wip2
    test "post can be upvote && upvotes_count should inc by 1",
         ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, article} = CMS.upvote_article(:post, post.id, user)
      assert article.id == post.id
      assert article.upvotes_count == 1

      {:ok, article} = CMS.upvote_article(:post, post.id, user2)
      assert article.upvotes_count == 2
    end

    @tag :wip2
    test "post can be undo upvote && upvotes_count should dec by 1",
         ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, article} = CMS.upvote_article(:post, post.id, user)
      assert article.id == post.id
      assert article.upvotes_count == 1

      {:ok, article} = CMS.undo_upvote_article(:post, post.id, user2)
      assert article.upvotes_count == 0
    end
  end
end
