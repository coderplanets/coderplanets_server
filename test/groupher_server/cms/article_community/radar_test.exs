defmodule GroupherServer.Test.CMS.ArticleCommunity.Radar do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Radar

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, radar} = db_insert(:radar)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    radar_attrs = mock_attrs(:radar, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 radar radar_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created radar has origial community info", ~m(user community radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, radar} = ORM.find(Radar, radar.id, preload: :original_community)

      assert radar.original_community_id == community.id
    end

    test "radar can be move to other community", ~m(user community community2 radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      assert radar.original_community_id == community.id

      {:ok, _} = CMS.move_article(:radar, radar.id, community2.id)
      {:ok, radar} = ORM.find(Radar, radar.id, preload: [:original_community, :communities])

      assert radar.original_community.id == community2.id
      assert exist_in?(community2, radar.communities)
    end

    test "tags should be clean after radar move to other community",
         ~m(user community community2 radar_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :radar, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :radar, article_tag_attrs2, user)

      {:ok, _radar} = CMS.set_article_tag(:radar, radar.id, article_tag.id)
      {:ok, radar} = CMS.set_article_tag(:radar, radar.id, article_tag2.id)

      assert radar.article_tags |> length == 2
      assert radar.original_community_id == community.id

      {:ok, _} = CMS.move_article(:radar, radar.id, community2.id)

      {:ok, radar} =
        ORM.find(Radar, radar.id, preload: [:original_community, :communities, :article_tags])

      assert radar.article_tags |> length == 0
      assert radar.original_community.id == community2.id
      assert exist_in?(community2, radar.communities)
    end

    test "radar move to other community with new tag",
         ~m(user community community2 radar_attrs)a do
      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, article_tag0} = CMS.create_article_tag(community, :radar, article_tag_attrs0, user)
      {:ok, article_tag} = CMS.create_article_tag(community2, :radar, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :radar, article_tag_attrs2, user)

      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, _} = CMS.set_article_tag(:radar, radar.id, article_tag0.id)
      {:ok, _} = CMS.set_article_tag(:radar, radar.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:radar, radar.id, article_tag2.id)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: [:article_tags])
      assert radar.article_tags |> length == 3

      {:ok, _} =
        CMS.move_article(:radar, radar.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, radar} =
        ORM.find(Radar, radar.id, preload: [:original_community, :communities, :article_tags])

      assert radar.original_community.id == community2.id
      assert radar.article_tags |> length == 2

      assert not exist_in?(article_tag0, radar.article_tags)
      assert exist_in?(article_tag, radar.article_tags)
      assert exist_in?(article_tag2, radar.article_tags)
    end

    test "radar can be mirror to other community", ~m(user community community2 radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :communities)
      assert radar.communities |> length == 1

      assert exist_in?(community, radar.communities)

      {:ok, _} = CMS.mirror_article(:radar, radar.id, community2.id)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :communities)
      assert radar.communities |> length == 2

      assert exist_in?(community, radar.communities)
      assert exist_in?(community2, radar.communities)
    end

    test "radar can be mirror to other community with tags",
         ~m(user community community2 radar_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community2, :radar, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :radar, article_tag_attrs2, user)

      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, _} =
        CMS.mirror_article(:radar, radar.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :article_tags)
      assert radar.article_tags |> length == 2

      assert exist_in?(article_tag, radar.article_tags)
      assert exist_in?(article_tag2, radar.article_tags)
    end

    test "radar can be unmirror from community",
         ~m(user community community2 community3 radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, _} = CMS.mirror_article(:radar, radar.id, community2.id)
      {:ok, _} = CMS.mirror_article(:radar, radar.id, community3.id)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :communities)
      assert radar.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:radar, radar.id, community3.id)
      {:ok, radar} = ORM.find(Radar, radar.id, preload: :communities)
      assert radar.communities |> length == 2

      assert not exist_in?(community3, radar.communities)
    end

    test "radar can be unmirror from community with tags",
         ~m(user community community2 community3 radar_attrs)a do
      article_tag_attrs2 = mock_attrs(:article_tag)
      article_tag_attrs3 = mock_attrs(:article_tag)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :radar, article_tag_attrs2, user)
      {:ok, article_tag3} = CMS.create_article_tag(community3, :radar, article_tag_attrs3, user)

      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, _} = CMS.mirror_article(:radar, radar.id, community2.id, [article_tag2.id])
      {:ok, _} = CMS.mirror_article(:radar, radar.id, community3.id, [article_tag3.id])

      {:ok, _} = CMS.unmirror_article(:radar, radar.id, community3.id)
      {:ok, radar} = ORM.find(Radar, radar.id, preload: :article_tags)

      assert exist_in?(article_tag2, radar.article_tags)
      assert not exist_in?(article_tag3, radar.article_tags)
    end

    test "radar can not unmirror from original community",
         ~m(user community community2 community3 radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, _} = CMS.mirror_article(:radar, radar.id, community2.id)
      {:ok, _} = CMS.mirror_article(:radar, radar.id, community3.id)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :communities)
      assert radar.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:radar, radar.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end

    test "radar can be mirror to home", ~m(community radar_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      assert radar.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:radar, radar.id)
      {:ok, radar} = ORM.find(Radar, radar.id, preload: [:original_community, :communities])

      assert radar.original_community_id == community.id
      assert radar.communities |> length == 2

      assert exist_in?(community, radar.communities)
      assert exist_in?(home_community, radar.communities)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:radar, filter)

      assert exist_in?(radar, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:radar, filter)

      assert exist_in?(radar, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "radar can be mirror to home with tags", ~m(community radar_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(home_community, :radar, article_tag_attrs0, user)

      {:ok, article_tag} = CMS.create_article_tag(home_community, :radar, article_tag_attrs, user)

      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      assert radar.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:radar, radar.id, [article_tag0.id, article_tag.id])

      {:ok, radar} =
        ORM.find(Radar, radar.id, preload: [:original_community, :communities, :article_tags])

      assert radar.original_community_id == community.id
      assert radar.communities |> length == 2

      assert exist_in?(community, radar.communities)
      assert exist_in?(home_community, radar.communities)

      assert radar.article_tags |> length == 2
      assert exist_in?(article_tag0, radar.article_tags)
      assert exist_in?(article_tag, radar.article_tags)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:radar, filter)

      assert exist_in?(radar, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:radar, filter)

      assert exist_in?(radar, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "radar can be move to blackhole", ~m(community radar_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      assert radar.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:radar, radar.id)
      {:ok, radar} = ORM.find(Radar, radar.id, preload: [:original_community, :communities])

      assert radar.original_community.id == blackhole_community.id
      assert radar.communities |> length == 1

      assert exist_in?(blackhole_community, radar.communities)

      filter = %{page: 1, size: 10, community: blackhole_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:radar, filter)

      assert exist_in?(radar, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "radar can be move to blackhole with tags", ~m(community radar_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(blackhole_community, :radar, article_tag_attrs0, user)

      {:ok, article_tag} =
        CMS.create_article_tag(blackhole_community, :radar, article_tag_attrs, user)

      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)
      {:ok, _} = CMS.set_article_tag(:radar, radar.id, article_tag0.id)

      assert radar.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:radar, radar.id, [article_tag.id])

      {:ok, radar} =
        ORM.find(Radar, radar.id, preload: [:original_community, :communities, :article_tags])

      assert radar.original_community.id == blackhole_community.id
      assert radar.communities |> length == 1
      assert radar.article_tags |> length == 1

      assert exist_in?(blackhole_community, radar.communities)
      assert exist_in?(article_tag, radar.article_tags)
    end
  end
end
