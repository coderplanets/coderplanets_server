defmodule GroupherServer.Test.CMS.ArticleCommunity.Guide do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Guide

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, guide} = db_insert(:guide)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    guide_attrs = mock_attrs(:guide, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 guide guide_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created guide has origial community info", ~m(user community guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, guide} = ORM.find(Guide, guide.id, preload: :original_community)

      assert guide.original_community_id == community.id
    end

    test "guide can be move to other community", ~m(user community community2 guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      assert guide.original_community_id == community.id

      {:ok, _} = CMS.move_article(:guide, guide.id, community2.id)
      {:ok, guide} = ORM.find(Guide, guide.id, preload: [:original_community, :communities])

      assert guide.original_community.id == community2.id
      assert not is_nil(Enum.find(guide.communities, &(&1.id == community2.id)))
    end

    @tag :wip
    test "tags should be clean after guide move to other community",
         ~m(user community community2 guide_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :guide, article_tag_attrs2, user)

      {:ok, _guide} = CMS.set_article_tag(:guide, guide.id, article_tag.id)
      {:ok, guide} = CMS.set_article_tag(:guide, guide.id, article_tag2.id)

      assert guide.article_tags |> length == 2
      assert guide.original_community_id == community.id

      {:ok, _} = CMS.move_article(:guide, guide.id, community2.id)

      {:ok, guide} =
        ORM.find(Guide, guide.id, preload: [:original_community, :communities, :article_tags])

      assert guide.article_tags |> length == 0
      assert guide.original_community.id == community2.id
      assert not is_nil(Enum.find(guide.communities, &(&1.id == community2.id)))
    end

    test "guide can be mirror to other community", ~m(user community community2 guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :communities)
      assert guide.communities |> length == 1

      assert not is_nil(Enum.find(guide.communities, &(&1.id == community.id)))

      {:ok, _} = CMS.mirror_article(:guide, guide.id, community2.id)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :communities)
      assert guide.communities |> length == 2
      assert not is_nil(Enum.find(guide.communities, &(&1.id == community.id)))
      assert not is_nil(Enum.find(guide.communities, &(&1.id == community2.id)))
    end

    test "guide can be unmirror from community",
         ~m(user community community2 community3 guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _} = CMS.mirror_article(:guide, guide.id, community2.id)
      {:ok, _} = CMS.mirror_article(:guide, guide.id, community3.id)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :communities)
      assert guide.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:guide, guide.id, community3.id)
      {:ok, guide} = ORM.find(Guide, guide.id, preload: :communities)
      assert guide.communities |> length == 2

      assert is_nil(Enum.find(guide.communities, &(&1.id == community3.id)))
    end

    test "guide can not unmirror from original community",
         ~m(user community community2 community3 guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _} = CMS.mirror_article(:guide, guide.id, community2.id)
      {:ok, _} = CMS.mirror_article(:guide, guide.id, community3.id)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :communities)
      assert guide.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:guide, guide.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end
  end
end
