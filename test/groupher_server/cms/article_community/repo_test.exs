defmodule GroupherServer.Test.CMS.ArticleCommunity.Repo do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, repo} = db_insert(:repo)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)
    {:ok, community3} = db_insert(:community)

    repo_attrs = mock_attrs(:repo, %{community_id: community.id})

    {:ok, ~m(user user2 community community2 community3 repo repo_attrs)a}
  end

  describe "[article mirror/move]" do
    test "created repo has origial community info", ~m(user community repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: :original_community)

      assert repo.original_community_id == community.id
    end

    @tag :wip2
    test "repo can be move to other community", ~m(user community community2 repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      assert repo.original_community_id == community.id

      {:ok, _} = CMS.move_article(:repo, repo.id, community2.id)
      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: [:original_community, :communities])

      assert repo.original_community.id == community2.id
      assert is_nil(Enum.find(repo.communities, &(&1.id == community2.id)))
    end

    test "repo can be mirror to other community", ~m(user community community2 repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 1

      assert not is_nil(Enum.find(repo.communities, &(&1.id == community.id)))

      {:ok, _} = CMS.mirror_community(:repo, repo.id, community2.id)

      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 2
      assert not is_nil(Enum.find(repo.communities, &(&1.id == community.id)))
      assert not is_nil(Enum.find(repo.communities, &(&1.id == community2.id)))
    end

    test "repo can be unmirror from community",
         ~m(user community community2 community3 repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, _} = CMS.mirror_community(:repo, repo.id, community2.id)
      {:ok, _} = CMS.mirror_community(:repo, repo.id, community3.id)

      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 3

      {:ok, _} = CMS.unmirror_community(:repo, repo.id, community3.id)
      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 2

      assert is_nil(Enum.find(repo.communities, &(&1.id == community3.id)))
    end

    test "repo can not unmirror from original community",
         ~m(user community community2 community3 repo_attrs)a do
      {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, _} = CMS.mirror_community(:repo, repo.id, community2.id)
      {:ok, _} = CMS.mirror_community(:repo, repo.id, community3.id)

      {:ok, repo} = ORM.find(CMS.Repo, repo.id, preload: :communities)
      assert repo.communities |> length == 3

      {:error, reason} = CMS.unmirror_community(:repo, repo.id, community.id)
      assert reason |> is_error?(:mirror_community)
    end
  end
end
