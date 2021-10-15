defmodule GroupherServer.Test.CMS.ArticleCommunity.Post do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Post

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, post} = db_insert(:post)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 post post_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created post has origial community info", ~m(user community post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, post} = ORM.find(Post, post.id, preload: :original_community)

      assert post.original_community_id == community.id
    end

    test "post can be move to other community", ~m(user community community2 post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      assert post.original_community_id == community.id

      {:ok, _} = CMS.move_article(:post, post.id, community2.id)
      {:ok, post} = ORM.find(Post, post.id, preload: [:original_community, :communities])

      assert post.original_community.id == community2.id
      assert not is_nil(Enum.find(post.communities, &(&1.id == community2.id)))
    end

    @tag :wip
    test "tags should be clean after post move to other community",
         ~m(user community community2 post_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :post, article_tag_attrs2, user)

      {:ok, _post} = CMS.set_article_tag(:post, post.id, article_tag.id)
      {:ok, post} = CMS.set_article_tag(:post, post.id, article_tag2.id)

      assert post.article_tags |> length == 2
      assert post.original_community_id == community.id

      {:ok, _} = CMS.move_article(:post, post.id, community2.id)

      {:ok, post} =
        ORM.find(Post, post.id, preload: [:original_community, :communities, :article_tags])

      assert post.article_tags |> length == 0
      assert post.original_community.id == community2.id
      assert not is_nil(Enum.find(post.communities, &(&1.id == community2.id)))
    end

    test "post can be mirror to other community", ~m(user community community2 post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, post} = ORM.find(Post, post.id, preload: :communities)
      assert post.communities |> length == 1

      assert not is_nil(Enum.find(post.communities, &(&1.id == community.id)))

      {:ok, _} = CMS.mirror_article(:post, post.id, community2.id)

      {:ok, post} = ORM.find(Post, post.id, preload: :communities)
      assert post.communities |> length == 2
      assert not is_nil(Enum.find(post.communities, &(&1.id == community.id)))
      assert not is_nil(Enum.find(post.communities, &(&1.id == community2.id)))
    end

    test "post can be unmirror from community",
         ~m(user community community2 community3 post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _} = CMS.mirror_article(:post, post.id, community2.id)
      {:ok, _} = CMS.mirror_article(:post, post.id, community3.id)

      {:ok, post} = ORM.find(Post, post.id, preload: :communities)
      assert post.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:post, post.id, community3.id)
      {:ok, post} = ORM.find(Post, post.id, preload: :communities)
      assert post.communities |> length == 2

      assert is_nil(Enum.find(post.communities, &(&1.id == community3.id)))
    end

    test "post can not unmirror from original community",
         ~m(user community community2 community3 post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _} = CMS.mirror_article(:post, post.id, community2.id)
      {:ok, _} = CMS.mirror_article(:post, post.id, community3.id)

      {:ok, post} = ORM.find(Post, post.id, preload: :communities)
      assert post.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:post, post.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end
  end
end
