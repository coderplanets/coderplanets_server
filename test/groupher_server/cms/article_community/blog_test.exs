defmodule GroupherServer.Test.CMS.ArticleCommunity.Blog do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Blog

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, blog} = db_insert(:blog)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    blog_attrs = mock_attrs(:blog, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 blog blog_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created blog has origial community info", ~m(user community blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, blog} = ORM.find(Blog, blog.id, preload: :original_community)

      assert blog.original_community_id == community.id
    end

    test "blog can be move to other community", ~m(user community community2 blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      assert blog.original_community_id == community.id

      {:ok, _} = CMS.move_article(:blog, blog.id, community2.id)
      {:ok, blog} = ORM.find(Blog, blog.id, preload: [:original_community, :communities])

      assert blog.original_community.id == community2.id
      assert not is_nil(Enum.find(blog.communities, &(&1.id == community2.id)))
    end

    test "blog can be mirror to other community", ~m(user community community2 blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)

      {:ok, blog} = ORM.find(Blog, blog.id, preload: :communities)
      assert blog.communities |> length == 1

      assert not is_nil(Enum.find(blog.communities, &(&1.id == community.id)))

      {:ok, _} = CMS.mirror_article(:blog, blog.id, community2.id)

      {:ok, blog} = ORM.find(Blog, blog.id, preload: :communities)
      assert blog.communities |> length == 2
      assert not is_nil(Enum.find(blog.communities, &(&1.id == community.id)))
      assert not is_nil(Enum.find(blog.communities, &(&1.id == community2.id)))
    end

    @tag :wip
    test "tags should be clean after blog move to other community",
         ~m(user community community2 blog_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :blog, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :blog, article_tag_attrs2, user)

      {:ok, _blog} = CMS.set_article_tag(:blog, blog.id, article_tag.id)
      {:ok, blog} = CMS.set_article_tag(:blog, blog.id, article_tag2.id)

      assert blog.article_tags |> length == 2
      assert blog.original_community_id == community.id

      {:ok, _} = CMS.move_article(:blog, blog.id, community2.id)

      {:ok, blog} =
        ORM.find(Blog, blog.id, preload: [:original_community, :communities, :article_tags])

      assert blog.article_tags |> length == 0
      assert blog.original_community.id == community2.id
      assert not is_nil(Enum.find(blog.communities, &(&1.id == community2.id)))
    end

    test "blog can be unmirror from community",
         ~m(user community community2 community3 blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, _} = CMS.mirror_article(:blog, blog.id, community2.id)
      {:ok, _} = CMS.mirror_article(:blog, blog.id, community3.id)

      {:ok, blog} = ORM.find(Blog, blog.id, preload: :communities)
      assert blog.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:blog, blog.id, community3.id)
      {:ok, blog} = ORM.find(Blog, blog.id, preload: :communities)
      assert blog.communities |> length == 2

      assert is_nil(Enum.find(blog.communities, &(&1.id == community3.id)))
    end

    test "blog can not unmirror from original community",
         ~m(user community community2 community3 blog_attrs)a do
      {:ok, blog} = CMS.create_article(community, :blog, blog_attrs, user)
      {:ok, _} = CMS.mirror_article(:blog, blog.id, community2.id)
      {:ok, _} = CMS.mirror_article(:blog, blog.id, community3.id)

      {:ok, blog} = ORM.find(Blog, blog.id, preload: :communities)
      assert blog.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:blog, blog.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end
  end
end
