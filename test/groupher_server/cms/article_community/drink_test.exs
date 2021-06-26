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
      assert not is_nil(Enum.find(drink.communities, &(&1.id == community2.id)))
    end

    test "drink can be mirror to other community", ~m(user community community2 drink_attrs)a do
      {:ok, drink} = CMS.create_article(community, :drink, drink_attrs, user)

      {:ok, drink} = ORM.find(Drink, drink.id, preload: :communities)
      assert drink.communities |> length == 1

      assert not is_nil(Enum.find(drink.communities, &(&1.id == community.id)))

      {:ok, _} = CMS.mirror_article(:drink, drink.id, community2.id)

      {:ok, drink} = ORM.find(Drink, drink.id, preload: :communities)
      assert drink.communities |> length == 2
      assert not is_nil(Enum.find(drink.communities, &(&1.id == community.id)))
      assert not is_nil(Enum.find(drink.communities, &(&1.id == community2.id)))
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

      assert is_nil(Enum.find(drink.communities, &(&1.id == community3.id)))
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
  end
end
