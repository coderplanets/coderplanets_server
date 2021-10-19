defmodule GroupherServer.Test.CMS.ArticleCommunity.Works do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Works

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, works} = db_insert(:works)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    works_attrs = mock_attrs(:works, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 works works_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created works has origial community info", ~m(user community works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, works} = ORM.find(Works, works.id, preload: :original_community)

      assert works.original_community_id == community.id
    end

    test "works can be move to other community", ~m(user community community2 works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      assert works.original_community_id == community.id

      {:ok, _} = CMS.move_article(:works, works.id, community2.id)
      {:ok, works} = ORM.find(Works, works.id, preload: [:original_community, :communities])

      assert works.original_community.id == community2.id
      assert exist_in?(community2, works.communities)
    end

    test "tags should be clean after works move to other community",
         ~m(user community community2 works_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :works, article_tag_attrs2, user)

      {:ok, _works} = CMS.set_article_tag(:works, works.id, article_tag.id)
      {:ok, works} = CMS.set_article_tag(:works, works.id, article_tag2.id)

      assert works.article_tags |> length == 2
      assert works.original_community_id == community.id

      {:ok, _} = CMS.move_article(:works, works.id, community2.id)

      {:ok, works} =
        ORM.find(Works, works.id, preload: [:original_community, :communities, :article_tags])

      assert works.article_tags |> length == 0
      assert works.original_community.id == community2.id
      assert exist_in?(community2, works.communities)
    end

    test "works move to other community with new tag",
         ~m(user community community2 works_attrs)a do
      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, article_tag0} = CMS.create_article_tag(community, :works, article_tag_attrs0, user)
      {:ok, article_tag} = CMS.create_article_tag(community2, :works, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :works, article_tag_attrs2, user)

      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, _} = CMS.set_article_tag(:works, works.id, article_tag0.id)
      {:ok, _} = CMS.set_article_tag(:works, works.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:works, works.id, article_tag2.id)

      {:ok, works} = ORM.find(Works, works.id, preload: [:article_tags])
      assert works.article_tags |> length == 3

      {:ok, _} =
        CMS.move_article(:works, works.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, works} =
        ORM.find(Works, works.id, preload: [:original_community, :communities, :article_tags])

      assert works.original_community.id == community2.id
      assert works.article_tags |> length == 2

      assert not exist_in?(article_tag0, works.article_tags)
      assert exist_in?(article_tag, works.article_tags)
      assert exist_in?(article_tag2, works.article_tags)
    end

    test "works can be mirror to other community", ~m(user community community2 works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      {:ok, works} = ORM.find(Works, works.id, preload: :communities)
      assert works.communities |> length == 1

      assert exist_in?(community, works.communities)

      {:ok, _} = CMS.mirror_article(:works, works.id, community2.id)

      {:ok, works} = ORM.find(Works, works.id, preload: :communities)
      assert works.communities |> length == 2

      assert exist_in?(community, works.communities)
      assert exist_in?(community2, works.communities)
    end

    test "works can be mirror to other community with tags",
         ~m(user community community2 works_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community2, :works, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :works, article_tag_attrs2, user)

      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      {:ok, _} =
        CMS.mirror_article(:works, works.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, works} = ORM.find(Works, works.id, preload: :article_tags)
      assert works.article_tags |> length == 2

      assert exist_in?(article_tag, works.article_tags)
      assert exist_in?(article_tag2, works.article_tags)
    end

    test "works can be unmirror from community",
         ~m(user community community2 community3 works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, _} = CMS.mirror_article(:works, works.id, community2.id)
      {:ok, _} = CMS.mirror_article(:works, works.id, community3.id)

      {:ok, works} = ORM.find(Works, works.id, preload: :communities)
      assert works.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:works, works.id, community3.id)
      {:ok, works} = ORM.find(Works, works.id, preload: :communities)
      assert works.communities |> length == 2

      assert not exist_in?(community3, works.communities)
    end

    test "works can be unmirror from community with tags",
         ~m(user community community2 community3 works_attrs)a do
      article_tag_attrs2 = mock_attrs(:article_tag)
      article_tag_attrs3 = mock_attrs(:article_tag)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :works, article_tag_attrs2, user)
      {:ok, article_tag3} = CMS.create_article_tag(community3, :works, article_tag_attrs3, user)

      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, _} = CMS.mirror_article(:works, works.id, community2.id, [article_tag2.id])
      {:ok, _} = CMS.mirror_article(:works, works.id, community3.id, [article_tag3.id])

      {:ok, _} = CMS.unmirror_article(:works, works.id, community3.id)
      {:ok, works} = ORM.find(Works, works.id, preload: :article_tags)

      assert exist_in?(article_tag2, works.article_tags)
      assert not exist_in?(article_tag3, works.article_tags)
    end

    test "works can not unmirror from original community",
         ~m(user community community2 community3 works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, _} = CMS.mirror_article(:works, works.id, community2.id)
      {:ok, _} = CMS.mirror_article(:works, works.id, community3.id)

      {:ok, works} = ORM.find(Works, works.id, preload: :communities)
      assert works.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:works, works.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end

    test "works can be mirror to home", ~m(community works_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      assert works.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:works, works.id)
      {:ok, works} = ORM.find(Works, works.id, preload: [:original_community, :communities])

      assert works.original_community_id == community.id
      assert works.communities |> length == 2

      assert exist_in?(community, works.communities)
      assert exist_in?(home_community, works.communities)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:works, filter)

      assert exist_in?(works, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:works, filter)

      assert exist_in?(works, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "works can be mirror to home with tags", ~m(community works_attrs user)a do
      {:ok, home_community} = db_insert(:community, %{raw: "home"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(home_community, :works, article_tag_attrs0, user)

      {:ok, article_tag} = CMS.create_article_tag(home_community, :works, article_tag_attrs, user)

      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      assert works.original_community_id == community.id

      {:ok, _} = CMS.mirror_to_home(:works, works.id, [article_tag0.id, article_tag.id])

      {:ok, works} =
        ORM.find(Works, works.id, preload: [:original_community, :communities, :article_tags])

      assert works.original_community_id == community.id
      assert works.communities |> length == 2

      assert exist_in?(community, works.communities)
      assert exist_in?(home_community, works.communities)

      assert works.article_tags |> length == 2
      assert exist_in?(article_tag0, works.article_tags)
      assert exist_in?(article_tag, works.article_tags)

      filter = %{page: 1, size: 10, community: community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:works, filter)

      assert exist_in?(works, paged_articles.entries)
      assert paged_articles.total_count === 1

      filter = %{page: 1, size: 10, community: home_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:works, filter)

      assert exist_in?(works, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "works can be move to blackhole", ~m(community works_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      assert works.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:works, works.id)
      {:ok, works} = ORM.find(Works, works.id, preload: [:original_community, :communities])

      assert works.original_community.id == blackhole_community.id
      assert works.communities |> length == 1

      assert exist_in?(blackhole_community, works.communities)

      filter = %{page: 1, size: 10, community: blackhole_community.raw}
      {:ok, paged_articles} = CMS.paged_articles(:works, filter)

      assert exist_in?(works, paged_articles.entries)
      assert paged_articles.total_count === 1
    end

    test "works can be move to blackhole with tags", ~m(community works_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(blackhole_community, :works, article_tag_attrs0, user)

      {:ok, article_tag} =
        CMS.create_article_tag(blackhole_community, :works, article_tag_attrs, user)

      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, _} = CMS.set_article_tag(:works, works.id, article_tag0.id)

      assert works.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:works, works.id, [article_tag.id])

      {:ok, works} =
        ORM.find(Works, works.id, preload: [:original_community, :communities, :article_tags])

      assert works.original_community.id == blackhole_community.id
      assert works.communities |> length == 1
      assert works.article_tags |> length == 1

      assert exist_in?(blackhole_community, works.communities)
      assert exist_in?(article_tag, works.article_tags)
    end
  end
end
