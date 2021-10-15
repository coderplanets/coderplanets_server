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
      assert not is_nil(Enum.find(radar.communities, &(&1.id == community2.id)))
    end

    @tag :wip
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
      assert not is_nil(Enum.find(radar.communities, &(&1.id == community2.id)))
    end

    test "radar can be mirror to other community", ~m(user community community2 radar_attrs)a do
      {:ok, radar} = CMS.create_article(community, :radar, radar_attrs, user)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :communities)
      assert radar.communities |> length == 1

      assert not is_nil(Enum.find(radar.communities, &(&1.id == community.id)))

      {:ok, _} = CMS.mirror_article(:radar, radar.id, community2.id)

      {:ok, radar} = ORM.find(Radar, radar.id, preload: :communities)
      assert radar.communities |> length == 2
      assert not is_nil(Enum.find(radar.communities, &(&1.id == community.id)))
      assert not is_nil(Enum.find(radar.communities, &(&1.id == community2.id)))
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

      assert is_nil(Enum.find(radar.communities, &(&1.id == community3.id)))
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
  end
end
