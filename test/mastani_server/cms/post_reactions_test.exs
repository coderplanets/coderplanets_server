defmodule MastaniServer.Test.PostReactionsTest do
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory

  alias MastaniServer.CMS
  alias MastaniServer.Accounts
  alias MastaniServer.Repo

  @valid_user mock_attrs(:user)
  @valid_community mock_attrs(:community)
  @valid_post mock_attrs(:post, %{community: @valid_community.title})

  setup do
    db_insert(:user, @valid_user)
    db_insert(:community, %{title: @valid_community.title})
    :ok
  end

  describe "[cms post favorite reaction]" do
    test "favorite and undo favorite reaction to post" do
      user = Repo.get_by(Accounts.User, nickname: @valid_user.nickname)
      {:ok, post} = CMS.create_content(:post, %CMS.Author{user_id: user.id}, @valid_post)

      {:ok, _} = CMS.reaction(:post, :favorite, post.id, user.id)
      {:ok, reaction_users} = CMS.reaction_users(:post, :favorite, post.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      # undo test
      {:ok, _} = CMS.undo_reaction(:post, :favorite, post.id, user.id)
      {:ok, reaction_users2} = CMS.reaction_users(:post, :favorite, post.id, %{page: 1, size: 1})
      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end
  end
end
