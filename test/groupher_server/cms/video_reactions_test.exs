defmodule GroupherServer.Test.CMS.VideoReactions do
  use GroupherServer.TestTools

  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    video_attrs = mock_attrs(:video, %{community_id: community.id})

    {:ok, ~m(user community video_attrs)a}
  end

  describe "[cms video star/favorite reaction]" do
    test "star and undo star reaction to video", ~m(user community video_attrs)a do
      {:ok, video} = CMS.create_content(community, :video, video_attrs, user)

      {:ok, _} = CMS.reaction(:video, :star, video.id, user)
      {:ok, reaction_users} = CMS.reaction_users(:video, :star, video.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      {:ok, _} = CMS.undo_reaction(:video, :star, video.id, user)
      {:ok, reaction_users2} = CMS.reaction_users(:video, :star, video.id, %{page: 1, size: 1})
      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end

    test "favorite and undo favorite reaction to video", ~m(user community video_attrs)a do
      {:ok, video} = CMS.create_content(community, :video, video_attrs, user)

      {:ok, _} = CMS.reaction(:video, :favorite, video.id, user)
      {:ok, reaction_users} = CMS.reaction_users(:video, :favorite, video.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      {:ok, _} = CMS.undo_reaction(:video, :favorite, video.id, user)

      {:ok, reaction_users2} =
        CMS.reaction_users(:video, :favorite, video.id, %{page: 1, size: 1})

      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end
  end
end
