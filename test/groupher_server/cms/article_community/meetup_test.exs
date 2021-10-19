defmodule GroupherServer.Test.CMS.ArticleCommunity.Meetup do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Meetup

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, meetup} = db_insert(:meetup)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    meetup_attrs = mock_attrs(:meetup, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 meetup meetup_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created meetup has origial community info", ~m(user community meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :original_community)

      assert meetup.original_community_id == community.id
    end

    test "meetup can be move to other community", ~m(user community community2 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      assert meetup.original_community_id == community.id

      {:ok, _} = CMS.move_article(:meetup, meetup.id, community2.id)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: [:original_community, :communities])

      assert meetup.original_community.id == community2.id
      assert exist_in?(community2, meetup.communities)
    end

    test "tags should be clean after meetup move to other community",
         ~m(user community community2 meetup_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :meetup, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :meetup, article_tag_attrs2, user)

      {:ok, _meetup} = CMS.set_article_tag(:meetup, meetup.id, article_tag.id)
      {:ok, meetup} = CMS.set_article_tag(:meetup, meetup.id, article_tag2.id)

      assert meetup.article_tags |> length == 2
      assert meetup.original_community_id == community.id

      {:ok, _} = CMS.move_article(:meetup, meetup.id, community2.id)

      {:ok, meetup} =
        ORM.find(Meetup, meetup.id, preload: [:original_community, :communities, :article_tags])

      assert meetup.article_tags |> length == 0
      assert meetup.original_community.id == community2.id
      assert exist_in?(community2, meetup.communities)
    end

    test "meetup move to other community with new tag",
         ~m(user community community2 meetup_attrs)a do
      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, article_tag0} = CMS.create_article_tag(community, :meetup, article_tag_attrs0, user)
      {:ok, article_tag} = CMS.create_article_tag(community2, :meetup, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :meetup, article_tag_attrs2, user)

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _} = CMS.set_article_tag(:meetup, meetup.id, article_tag0.id)
      {:ok, _} = CMS.set_article_tag(:meetup, meetup.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:meetup, meetup.id, article_tag2.id)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: [:article_tags])
      assert meetup.article_tags |> length == 3

      {:ok, _} =
        CMS.move_article(:meetup, meetup.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, meetup} =
        ORM.find(Meetup, meetup.id, preload: [:original_community, :communities, :article_tags])

      assert meetup.original_community.id == community2.id
      assert meetup.article_tags |> length == 2

      assert not exist_in?(article_tag0, meetup.article_tags)
      assert exist_in?(article_tag, meetup.article_tags)
      assert exist_in?(article_tag2, meetup.article_tags)
    end

    test "meetup can be mirror to other community", ~m(user community community2 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 1

      assert exist_in?(community, meetup.communities)

      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community2.id)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 2

      assert exist_in?(community, meetup.communities)
      assert exist_in?(community2, meetup.communities)
    end

    test "meetup can be mirror to other community with tags",
         ~m(user community community2 meetup_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community2, :meetup, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :meetup, article_tag_attrs2, user)

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)

      {:ok, _} =
        CMS.mirror_article(:meetup, meetup.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :article_tags)
      assert meetup.article_tags |> length == 2

      assert exist_in?(article_tag, meetup.article_tags)
      assert exist_in?(article_tag2, meetup.article_tags)
    end

    test "meetup can be unmirror from community",
         ~m(user community community2 community3 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community2.id)
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community3.id)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:meetup, meetup.id, community3.id)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 2

      assert not exist_in?(community3, meetup.communities)
    end

    test "meetup can be unmirror from community with tags",
         ~m(user community community2 community3 meetup_attrs)a do
      article_tag_attrs2 = mock_attrs(:article_tag)
      article_tag_attrs3 = mock_attrs(:article_tag)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :meetup, article_tag_attrs2, user)
      {:ok, article_tag3} = CMS.create_article_tag(community3, :meetup, article_tag_attrs3, user)

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community2.id, [article_tag2.id])
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community3.id, [article_tag3.id])

      {:ok, _} = CMS.unmirror_article(:meetup, meetup.id, community3.id)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :article_tags)

      assert exist_in?(article_tag2, meetup.article_tags)
      assert not exist_in?(article_tag3, meetup.article_tags)
    end

    test "meetup can not unmirror from original community",
         ~m(user community community2 community3 meetup_attrs)a do
      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community2.id)
      {:ok, _} = CMS.mirror_article(:meetup, meetup.id, community3.id)

      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: :communities)
      assert meetup.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:meetup, meetup.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end

    test "meetup can be mirror to home", ~m(community meetup_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      assert meetup.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:meetup, meetup.id)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: [:original_community, :communities])

      assert meetup.original_community_id == community.id
      assert meetup.communities |> length == 2

      assert exist_in?(community, meetup.communities)
      assert exist_in?(home_community, meetup.communities)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:meetup, filter)

      assert exist_in?(meetup, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:meetup, filter)

      assert exist_in?(meetup, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "meetup can be mirror to home with tags", ~m(community meetup_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(home_community, :meetup, article_tag_attrs0, user)

      {:ok, article_tag} =
        CMS.create_article_tag(home_community, :meetup, article_tag_attrs, user)

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      assert meetup.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:meetup, meetup.id, [article_tag0.id, article_tag.id])

      {:ok, meetup} =
        ORM.find(Meetup, meetup.id, preload: [:original_community, :communities, :article_tags])

      assert meetup.original_community_id == community.id
      assert meetup.communities |> length == 2

      assert exist_in?(community, meetup.communities)
      assert exist_in?(home_community, meetup.communities)

      assert meetup.article_tags |> length == 2
      assert exist_in?(article_tag0, meetup.article_tags)
      assert exist_in?(article_tag, meetup.article_tags)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:meetup, filter)

      assert exist_in?(meetup, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:meetup, filter)

      assert exist_in?(meetup, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "meetup can be move to blackhole", ~m(community meetup_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      assert meetup.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:meetup, meetup.id)
      {:ok, meetup} = ORM.find(Meetup, meetup.id, preload: [:original_community, :communities])

      assert meetup.original_community.id == blackhole_community.id
      assert meetup.communities |> length == 1

      assert exist_in?(blackhole_community, meetup.communities)

      filter = %{page: 1, size: 10, community: blackhole_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:meetup, filter)

      assert exist_in?(meetup, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "meetup can be move to blackhole with tags", ~m(community meetup_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(blackhole_community, :meetup, article_tag_attrs0, user)

      {:ok, article_tag} =
        CMS.create_article_tag(blackhole_community, :meetup, article_tag_attrs, user)

      {:ok, meetup} = CMS.create_article(community, :meetup, meetup_attrs, user)
      {:ok, _} = CMS.set_article_tag(:meetup, meetup.id, article_tag0.id)

      assert meetup.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:meetup, meetup.id, [article_tag.id])

      {:ok, meetup} =
        ORM.find(Meetup, meetup.id, preload: [:original_community, :communities, :article_tags])

      assert meetup.original_community.id == blackhole_community.id
      assert meetup.communities |> length == 1
      assert meetup.article_tags |> length == 1

      assert exist_in?(blackhole_community, meetup.communities)
      assert exist_in?(article_tag, meetup.article_tags)
    end
  end
end
