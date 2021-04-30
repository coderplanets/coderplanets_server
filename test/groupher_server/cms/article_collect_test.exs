defmodule GroupherServer.Test.ArticleCollect do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 community post_attrs)a}
  end

  describe "[cms post collect]" do
    @tag :wip2
    test "post can be collect && collects_count should inc by 1",
         ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, article} = CMS.collect_article(:post, post.id, user)
      assert article.id == post.id
      assert article.collects_count == 1

      {:ok, article} = CMS.collect_article(:post, post.id, user2)
      assert article.collects_count == 2
    end

    @tag :wip
    test "post can be undo collect && collects_count should dec by 1",
         ~m(user user2 community post_attrs)a do
      {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

      {:ok, article} = CMS.collect_article(:post, post.id, user)
      assert article.id == post.id
      assert article.collects_count == 1

      {:ok, article} = CMS.undo_collect_article(:post, post.id, user2)
      assert article.collects_count == 0
    end
  end
end