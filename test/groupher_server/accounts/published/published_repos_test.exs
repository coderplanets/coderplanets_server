defmodule GroupherServer.Test.Accounts.Published.Repo do
  use GroupherServer.TestTools

  alias GroupherServer.{Accounts, CMS}

  @publish_count 10

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, user2} = db_insert(:user)
    {:ok, community} = db_insert(:community)
    {:ok, community2} = db_insert(:community)

    {:ok, ~m(user user2 community community2)a}
  end

  describe "[publised repos]" do
    @tag :wip2
    test "create repo should update user published meta", ~m(community user)a do
      repo_attrs = mock_attrs(:repo, %{community_id: community.id})
      {:ok, _repo} = CMS.create_article(community, :repo, repo_attrs, user)
      {:ok, _repo} = CMS.create_article(community, :repo, repo_attrs, user)

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.published_repos_count == 2
    end

    test "fresh user get empty paged published repos", ~m(user)a do
      {:ok, results} = Accounts.published_articles(user, :repo, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published repos", ~m(user user2 community community2)a do
      pub_repos =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          repo_attrs = mock_attrs(:repo, %{community_id: community.id})
          {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

          acc ++ [repo]
        end)

      pub_repos2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          repo_attrs = mock_attrs(:repo, %{community_id: community2.id})
          {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user)

          acc ++ [repo]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        repo_attrs = mock_attrs(:repo, %{community_id: community.id})
        {:ok, repo} = CMS.create_article(community, :repo, repo_attrs, user2)

        acc ++ [repo]
      end)

      {:ok, results} = Accounts.published_articles(user, :repo, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_repo_id = pub_repos |> Enum.random() |> Map.get(:id)
      random_repo_id2 = pub_repos2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_repo_id))
      assert results.entries |> Enum.any?(&(&1.id == random_repo_id2))
    end
  end
end
