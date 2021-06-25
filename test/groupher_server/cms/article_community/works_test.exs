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
      assert not is_nil(Enum.find(works.communities, &(&1.id == community2.id)))
    end

    test "works can be mirror to other community", ~m(user community community2 works_attrs)a do
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      {:ok, works} = ORM.find(Works, works.id, preload: :communities)
      assert works.communities |> length == 1

      assert not is_nil(Enum.find(works.communities, &(&1.id == community.id)))

      {:ok, _} = CMS.mirror_article(:works, works.id, community2.id)

      {:ok, works} = ORM.find(Works, works.id, preload: :communities)
      assert works.communities |> length == 2
      assert not is_nil(Enum.find(works.communities, &(&1.id == community.id)))
      assert not is_nil(Enum.find(works.communities, &(&1.id == community2.id)))
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

      assert is_nil(Enum.find(works.communities, &(&1.id == community3.id)))
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
  end
end
