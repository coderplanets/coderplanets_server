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

    @tag :wip
    test "post can be move to other community", ~m(user community community2 post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      assert post.original_community_id == community.id

      {:ok, _} = CMS.move_article(:post, post.id, community2.id)
      {:ok, post} = ORM.find(Post, post.id, preload: [:original_community, :communities])

      assert post.original_community.id == community2.id
      assert exist_in?(community2, post.communities)
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
      assert exist_in?(community2, post.communities)
    end

    @tag :wip
    test "post move to other community with new tag", ~m(user community community2 post_attrs)a do
      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, article_tag0} = CMS.create_article_tag(community, :post, article_tag_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community2, :post, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :post, article_tag_attrs2, user)

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _} = CMS.set_article_tag(:post, post.id, article_tag0.id)
      {:ok, _} = CMS.set_article_tag(:post, post.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:post, post.id, article_tag2.id)

      {:ok, post} = ORM.find(Post, post.id, preload: [:article_tags])
      assert post.article_tags |> length == 3

      {:ok, _} =
        CMS.move_article(:post, post.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, post} =
        ORM.find(Post, post.id, preload: [:original_community, :communities, :article_tags])

      assert post.original_community.id == community2.id
      assert post.article_tags |> length == 2

      assert not exist_in?(article_tag0, post.article_tags)
      assert exist_in?(article_tag, post.article_tags)
      assert exist_in?(article_tag2, post.article_tags)
    end

    @tag :wip
    test "post can be mirror to other community", ~m(user community community2 post_attrs)a do
      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, post} = ORM.find(Post, post.id, preload: :communities)
      assert post.communities |> length == 1

      assert exist_in?(community, post.communities)

      {:ok, _} = CMS.mirror_article(:post, post.id, community2.id)

      {:ok, post} = ORM.find(Post, post.id, preload: :communities)
      assert post.communities |> length == 2

      assert exist_in?(community, post.communities)
      assert exist_in?(community2, post.communities)
    end

    @tag :wip
    test "post can be mirror to other community with tags",
         ~m(user community community2 post_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community2, :post, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :post, article_tag_attrs2, user)

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)

      {:ok, _} =
        CMS.mirror_article(:post, post.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, post} = ORM.find(Post, post.id, preload: :article_tags)
      assert post.article_tags |> length == 2

      assert exist_in?(article_tag, post.article_tags)
      assert exist_in?(article_tag2, post.article_tags)
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

      assert not exist_in?(community3, post.communities)
    end

    @tag :wip
    test "post can be unmirror from community with tags",
         ~m(user community community2 community3 post_attrs)a do
      article_tag_attrs2 = mock_attrs(:article_tag)
      article_tag_attrs3 = mock_attrs(:article_tag)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :post, article_tag_attrs2, user)
      {:ok, article_tag3} = CMS.create_article_tag(community3, :post, article_tag_attrs3, user)

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _} = CMS.mirror_article(:post, post.id, community2.id, [article_tag2.id])
      {:ok, _} = CMS.mirror_article(:post, post.id, community3.id, [article_tag3.id])

      {:ok, _} = CMS.unmirror_article(:post, post.id, community3.id)
      {:ok, post} = ORM.find(Post, post.id, preload: :article_tags)

      assert exist_in?(article_tag2, post.article_tags)
      assert not exist_in?(article_tag3, post.article_tags)
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

    @tag :wip
    test "post can be move to blackhole", ~m(community post_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      assert post.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:post, post.id)
      {:ok, post} = ORM.find(Post, post.id, preload: [:original_community, :communities])

      assert post.original_community.id == blackhole_community.id
      assert post.communities |> length == 1

      assert exist_in?(blackhole_community, post.communities)
    end

    @tag :wip
    test "post can be move to blackhole with tags", ~m(community post_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(blackhole_community, :post, article_tag_attrs, user)

      {:ok, article_tag} =
        CMS.create_article_tag(blackhole_community, :post, article_tag_attrs, user)

      {:ok, post} = CMS.create_article(community, :post, post_attrs, user)
      {:ok, _} = CMS.set_article_tag(:post, post.id, article_tag0.id)

      assert post.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:post, post.id, [article_tag.id])

      {:ok, post} =
        ORM.find(Post, post.id, preload: [:original_community, :communities, :article_tags])

      assert post.original_community.id == blackhole_community.id
      assert post.communities |> length == 1
      assert post.article_tags |> length == 1

      assert exist_in?(blackhole_community, post.communities)
      assert exist_in?(article_tag, post.article_tags)
    end
  end
end
