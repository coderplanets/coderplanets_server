defmodule MastaniServer.Test.CMS.RepoReactions do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    repo_attrs = mock_attrs(:repo, %{community_id: community.id})

    {:ok, ~m(user community repo_attrs)a}
  end

  describe "[cms repo star/favorite reaction]" do
    test "favorite and undo favorite reaction to repo", ~m(user community repo_attrs)a do
      {:ok, repo} = CMS.create_content(community, :repo, repo_attrs, user)

      {:ok, _} = CMS.reaction(:repo, :favorite, repo.id, user)
      {:ok, reaction_users} = CMS.reaction_users(:repo, :favorite, repo.id, %{page: 1, size: 1})
      reaction_users = reaction_users |> Map.get(:entries)
      assert 1 == reaction_users |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length

      # undo test
      {:ok, _} = CMS.undo_reaction(:repo, :favorite, repo.id, user)
      {:ok, reaction_users2} = CMS.reaction_users(:repo, :favorite, repo.id, %{page: 1, size: 1})
      reaction_users2 = reaction_users2 |> Map.get(:entries)

      assert 0 == reaction_users2 |> Enum.filter(fn ruser -> user.id == ruser.id end) |> length
    end
  end
end
