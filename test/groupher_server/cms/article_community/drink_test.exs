defmodule GroupherServer.Test.CMS.ArticleCommunity.Drink do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS
  alias CMS.Model.Drink

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, drink} = db_insert(:drink)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    drink_attrs = mock_attrs(:drink, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 drink drink_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created drink has origial community info", ~m(user community drink_attrs)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, drink} = ORM.find(Drink, drink.id, preload: :original_community)

      assert drink.original_community_id == community.id
    end

    test "drink can be move to other community", ~m(user community community2 drink_attrs)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      assert drink.original_community_id == community.id

      {:ok, _} = CMS.move_article(:drink, drink.id, community2.id)
      {:ok, drink} = ORM.find(Drink, drink.id, preload: [:original_community, :communities])

      assert drink.original_community.id == community2.id
      assert exist_in?(community2, drink.communities)
    end

    test "tags should be clean after drink move to other community",
         ~m(user community community2 drink_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community, :drink, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :drink, article_tag_attrs2, user)

      {:ok, _drink} = CMS.set_article_tag(:drink, drink.id, article_tag.id)
      {:ok, drink} = CMS.set_article_tag(:drink, drink.id, article_tag2.id)

      assert drink.article_tags |> length == 2
      assert drink.original_community_id == community.id

      {:ok, _} = CMS.move_article(:drink, drink.id, community2.id)

      {:ok, drink} =
        ORM.find(Drink, drink.id, preload: [:original_community, :communities, :article_tags])

      assert drink.article_tags |> length == 0
      assert drink.original_community.id == community2.id
      assert exist_in?(community2, drink.communities)
    end

    test "drink move to other community with new tag",
         ~m(user community community2 drink_attrs)a do
      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)

      {:ok, article_tag0} = CMS.create_article_tag(community, :drink, article_tag_attrs, user)
      {:ok, article_tag} = CMS.create_article_tag(community2, :drink, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :drink, article_tag_attrs2, user)

      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, _} = CMS.set_article_tag(:drink, drink.id, article_tag0.id)
      {:ok, _} = CMS.set_article_tag(:drink, drink.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:drink, drink.id, article_tag2.id)

      {:ok, drink} = ORM.find(Drink, drink.id, preload: [:article_tags])
      assert drink.article_tags |> length == 3

      {:ok, _} =
        CMS.move_article(:drink, drink.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, drink} =
        ORM.find(Drink, drink.id, preload: [:original_community, :communities, :article_tags])

      assert drink.original_community.id == community2.id
      assert drink.article_tags |> length == 2

      assert not exist_in?(article_tag0, drink.article_tags)
      assert exist_in?(article_tag, drink.article_tags)
      assert exist_in?(article_tag2, drink.article_tags)
    end

    test "drink can be mirror to other community", ~m(user community community2 drink_attrs)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

      {:ok, drink} = ORM.find(Drink, drink.id, preload: :communities)
      assert drink.communities |> length == 1

      assert exist_in?(community, drink.communities)

      {:ok, _} = CMS.mirror_article(:drink, drink.id, community2.id)

      {:ok, drink} = ORM.find(Drink, drink.id, preload: :communities)
      assert drink.communities |> length == 2

      assert exist_in?(community, drink.communities)
      assert exist_in?(community2, drink.communities)
    end

    test "drink can be mirror to other community with tags",
         ~m(user community community2 drink_attrs)a do
      article_tag_attrs = mock_attrs(:article_tag)
      article_tag_attrs2 = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community2, :drink, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :drink, article_tag_attrs2, user)

      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

      {:ok, _} =
        CMS.mirror_article(:drink, drink.id, community2.id, [article_tag.id, article_tag2.id])

      {:ok, drink} = ORM.find(Drink, drink.id, preload: :article_tags)
      assert drink.article_tags |> length == 2

      assert exist_in?(article_tag, drink.article_tags)
      assert exist_in?(article_tag2, drink.article_tags)
    end

    test "drink can be unmirror from community",
         ~m(user community community2 community3 drink_attrs)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, _} = CMS.mirror_article(:drink, drink.id, community2.id)
      {:ok, _} = CMS.mirror_article(:drink, drink.id, community3.id)

      {:ok, drink} = ORM.find(Drink, drink.id, preload: :communities)
      assert drink.communities |> length == 3

      {:ok, _} = CMS.unmirror_article(:drink, drink.id, community3.id)
      {:ok, drink} = ORM.find(Drink, drink.id, preload: :communities)
      assert drink.communities |> length == 2

      assert not exist_in?(community3, drink.communities)
    end

    test "drink can be unmirror from community with tags",
         ~m(user community community2 community3 drink_attrs)a do
      article_tag_attrs2 = mock_attrs(:article_tag)
      article_tag_attrs3 = mock_attrs(:article_tag)
      {:ok, article_tag2} = CMS.create_article_tag(community2, :drink, article_tag_attrs2, user)
      {:ok, article_tag3} = CMS.create_article_tag(community3, :drink, article_tag_attrs3, user)

      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, _} = CMS.mirror_article(:drink, drink.id, community2.id, [article_tag2.id])
      {:ok, _} = CMS.mirror_article(:drink, drink.id, community3.id, [article_tag3.id])

      {:ok, _} = CMS.unmirror_article(:drink, drink.id, community3.id)
      {:ok, drink} = ORM.find(Drink, drink.id, preload: :article_tags)

      assert exist_in?(article_tag2, drink.article_tags)
      assert not exist_in?(article_tag3, drink.article_tags)
    end

    test "drink can not unmirror from original community",
         ~m(user community community2 community3 drink_attrs)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, _} = CMS.mirror_article(:drink, drink.id, community2.id)
      {:ok, _} = CMS.mirror_article(:drink, drink.id, community3.id)

      {:ok, drink} = ORM.find(Drink, drink.id, preload: :communities)
      assert drink.communities |> length == 3

      {:error, reason} = CMS.unmirror_article(:drink, drink.id, community.id)
      assert reason |> is_error?(:mirror_article)
    end

    test "drink can be move to blackhole", ~m(community drink_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      assert drink.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:drink, drink.id)
      {:ok, drink} = ORM.find(Drink, drink.id, preload: [:original_community, :communities])

      assert drink.original_community.id == blackhole_community.id
      assert drink.communities |> length == 1

      assert exist_in?(blackhole_community, drink.communities)
    end

    test "drink can be move to blackhole with tags", ~m(community drink_attrs user)a do
      {:ok, blackhole_community} = db_insert(:community, %{raw: "blackhole"})

      article_tag_attrs0 = mock_attrs(:article_tag)
      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag0} =
        CMS.create_article_tag(blackhole_community, :drink, article_tag_attrs, user)

      {:ok, article_tag} =
        CMS.create_article_tag(blackhole_community, :drink, article_tag_attrs, user)

      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)
      {:ok, _} = CMS.set_article_tag(:drink, drink.id, article_tag0.id)

      assert drink.original_community_id == community.id

      {:ok, _} = CMS.move_to_blackhole(:drink, drink.id, [article_tag.id])

      {:ok, drink} =
        ORM.find(Drink, drink.id, preload: [:original_community, :communities, :article_tags])

      assert drink.original_community.id == blackhole_community.id
      assert drink.communities |> length == 1
      assert drink.article_tags |> length == 1

      assert exist_in?(blackhole_community, drink.communities)
      assert exist_in?(article_tag, drink.article_tags)
    end
  end
end
