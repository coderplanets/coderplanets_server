defmodule GroupherServer.Test.CMS.Artilces.RepoPin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, PinnedArticle}

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)

    {:ok, ~m(user community repo)a}
  end

  describe "[cms repo pin]" do
    test "can pin a repo", ~m(community repo)a do
      {:ok, _} = CMS.pin_article(:repo, repo.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{repo_id: repo.id})

      assert pind_article.repo_id == repo.id
    end

    test "one community & thread can only pin certern count of repo", ~m(community user)a do
      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, new_repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)
        {:ok, _} = CMS.pin_article(:repo, new_repo.id, community.id)
        acc
      end)

      {:ok, new_repo} = CMS.create_article(community, :repo, mock_attrs(:repo), user)
      {:error, reason} = CMS.pin_article(:repo, new_repo.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    test "can not pin a non-exsit repo", ~m(community)a do
      assert {:error, _} = CMS.pin_article(:repo, 8848, community.id)
    end

    test "can undo pin to a repo", ~m(community repo)a do
      {:ok, _} = CMS.pin_article(:repo, repo.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:repo, repo.id, community.id)

      assert {:error, _} = ORM.find_by(PinnedArticle, %{repo_id: repo.id})
    end
  end
end
