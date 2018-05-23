defmodule MastaniServer.Test.PostReactionsTest do
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import ShortMaps

  alias MastaniServer.CMS
  alias MastaniServer.Accounts
  # alias Helper.ORM

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    post_attrs = mock_attrs(:post, %{community_id: community.id})

    {:ok, ~m(user post_attrs)a}
  end

  describe "[cms post favorite reaction]" do
    test "favorite and undo favorite reaction to post", ~m(user post_attrs)a do
      # {:ok, user} = ORM.find_by(Accounts.User, nickname: @valid_user.nickname)
      {:ok, post} = CMS.create_content(:post, %Accounts.User{id: user.id}, post_attrs)

      {:ok, _} = CMS.reaction(:post, :favorite, post.id, %Accounts.User{id: user.id})
      {:ok, reaction_users} = CMS.reaction_users(:post, :favorite, post.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      # undo test
      {:ok, _} = CMS.undo_reaction(:post, :favorite, post.id, %Accounts.User{id: user.id})
      {:ok, reaction_users2} = CMS.reaction_users(:post, :favorite, post.id, %{page: 1, size: 1})
      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end
  end
end
