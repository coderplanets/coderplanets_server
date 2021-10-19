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
      assert exist_in?(community2, guide.communities)
    end

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
      assert exist_in?(community2, guide.communities)
    end

    test "guide move to other community with new tag",
         ~m(user community community2 guide_attrs)a do
      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, article_tag0} = CMS.create_article_tag(community, :guide, article_tag_attrs0, user)
      {:ok, article_tag} = CMS.create_article_tag(community2, :guide, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :guide, article_tag_attrs2, user)

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _} = CMS.set_article_tag(:guide, guide.id, article_tag0.id)
      {:ok, _} = CMS.set_article_tag(:guide, guide.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:guide, guide.id, article_tag2.id)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: [:article_tags])
      assert guide.article_tags |> length == 3

      {:ok, _} =
        CMS.move_article(:guide, guide.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, guide} =
        ORM.find(Guide, guide.id, preload: [:original_community, :communities, :article_tags])

      assert guide.original_community.id == community2.id
      assert guide.article_tags |> length == 2

      assert not exist_in?(article_tag0, guide.article_tags)
      assert exist_in?(article_tag, guide.article_tags)
      assert exist_in?(article_tag2, guide.article_tags)
    end

    test "guide can be mirror to other community", ~m(user community community2 guide_attrs)a do
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :communities)
      assert guide.communities |> length == 1

      assert exist_in?(community, guide.communities)

      {:ok, _} = CMS.mirror_article(:guide, guide.id, community2.id)

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :communities)
      assert guide.communities |> length == 2

      assert exist_in?(community, guide.communities)
      assert exist_in?(community2, guide.communities)
    end

    test "guide can be mirror to other community with tags",
         ~m(user community community2 guide_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community2, :guide, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :guide, article_tag_attrs2, user)

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      {:ok, _} =
        CMS.mirror_article(:guide, guide.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, guide} = ORM.find(Guide, guide.id, preload: :article_tags)
      assert guide.article_tags |> length == 2

      assert exist_in?(article_tag, guide.article_tags)
      assert exist_in?(article_tag2, guide.article_tags)
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

      assert not exist_in?(community3, guide.communities)
    end

    test "guide can be unmirror from community with tags",
         ~m(user community community2 community3 guide_attrs)a do
      article_tag_attrs2 = mock_attrs(:article_tag)
      article_tag_attrs3 = mock_attrs(:article_tag)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :guide, article_tag_attrs2, user)
      {:ok, article_tag3} = CMS.create_article_tag(community3, :guide, article_tag_attrs3, user)

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _} = CMS.mirror_article(:guide, guide.id, community2.id, [article_tag2.id])
      {:ok, _} = CMS.mirror_article(:guide, guide.id, community3.id, [article_tag3.id])

      {:ok, _} = CMS.unmirror_article(:guide, guide.id, community3.id)
      {:ok, guide} = ORM.find(Guide, guide.id, preload: :article_tags)

      assert exist_in?(article_tag2, guide.article_tags)
      assert not exist_in?(article_tag3, guide.article_tags)
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

    test "guide can be mirror to home", ~m(community guide_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      assert guide.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:guide, guide.id)
      {:ok, guide} = ORM.find(Guide, guide.id, preload: [:original_community, :communities])

      assert guide.original_community_id == community.id
      assert guide.communities |> length == 2

      assert exist_in?(community, guide.communities)
      assert exist_in?(home_community, guide.communities)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:guide, filter)

      assert exist_in?(guide, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:guide, filter)

      assert exist_in?(guide, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "guide can be mirror to home with tags", ~m(community guide_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(home_community, :guide, article_tag_attrs0, user)

      {:ok, article_tag} = CMS.create_article_tag(home_community, :guide, article_tag_attrs, user)

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      assert guide.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:guide, guide.id, [article_tag0.id, article_tag.id])

      {:ok, guide} =
        ORM.find(Guide, guide.id, preload: [:original_community, :communities, :article_tags])

      assert guide.original_community_id == community.id
      assert guide.communities |> length == 2

      assert exist_in?(community, guide.communities)
      assert exist_in?(home_community, guide.communities)

      assert guide.article_tags |> length == 2
      assert exist_in?(article_tag0, guide.article_tags)
      assert exist_in?(article_tag, guide.article_tags)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:guide, filter)

      assert exist_in?(guide, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:guide, filter)

      assert exist_in?(guide, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "guide can be move to blackhole", ~m(community guide_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      assert guide.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:guide, guide.id)
      {:ok, guide} = ORM.find(Guide, guide.id, preload: [:original_community, :communities])

      assert guide.original_community.id == blackhole_community.id
      assert guide.communities |> length == 1

      assert exist_in?(blackhole_community, guide.communities)

      filter = %{page: 1, size: 10, community: blackhole_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:guide, filter)

      assert exist_in?(guide, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "guide can be move to blackhole with tags", ~m(community guide_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(blackhole_community, :guide, article_tag_attrs0, user)

      {:ok, article_tag} =
        CMS.create_article_tag(blackhole_community, :guide, article_tag_attrs, user)

      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, _} = CMS.set_article_tag(:guide, guide.id, article_tag0.id)

      assert guide.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:guide, guide.id, [article_tag.id])

      {:ok, guide} =
        ORM.find(Guide, guide.id, preload: [:original_community, :communities, :article_tags])

      assert guide.original_community.id == blackhole_community.id
      assert guide.communities |> length == 1
      assert guide.article_tags |> length == 1

      assert exist_in?(blackhole_community, guide.communities)
      assert exist_in?(article_tag, guide.article_tags)
    end
  end
end
