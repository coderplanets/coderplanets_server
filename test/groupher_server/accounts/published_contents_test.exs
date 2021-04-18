defmodule GroupherServer.Test.Accounts.PublishedContents do
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

  describe "[Accounts Publised posts]" do
    test "fresh user get empty paged published posts", ~m(user)a do
      {:ok, results} = Accounts.published_contents(user, :post, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published posts", ~m(user user2 community community2)a do
      pub_posts =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          post_attrs = mock_attrs(:post, %{community_id: community.id})
          {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

          acc ++ [post]
        end)

      pub_posts2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          post_attrs = mock_attrs(:post, %{community_id: community2.id})
          {:ok, post} = CMS.create_content(community, :post, post_attrs, user)

          acc ++ [post]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        post_attrs = mock_attrs(:post, %{community_id: community.id})
        {:ok, post} = CMS.create_content(community, :post, post_attrs, user2)

        acc ++ [post]
      end)

      {:ok, results} = Accounts.published_contents(user, :post, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_post_id = pub_posts |> Enum.random() |> Map.get(:id)
      random_post_id2 = pub_posts2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_post_id))
      assert results.entries |> Enum.any?(&(&1.id == random_post_id2))
    end
  end

  describe "[Accounts Publised jobs]" do
    test "fresh user get empty paged published jobs", ~m(user)a do
      {:ok, results} = Accounts.published_contents(user, :job, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    @tag :wip
    test "user can get paged published jobs", ~m(user user2 community community2)a do
      pub_jobs =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          job_attrs = mock_attrs(:job, %{community_id: community.id})
          {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

          acc ++ [job]
        end)

      pub_jobs2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          job_attrs = mock_attrs(:job, %{community_id: community2.id})
          {:ok, job} = CMS.create_content(community, :job, job_attrs, user)

          acc ++ [job]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        job_attrs = mock_attrs(:job, %{community_id: community.id})
        {:ok, job} = CMS.create_content(community, :job, job_attrs, user2)

        acc ++ [job]
      end)

      {:ok, results} = Accounts.published_contents(user, :job, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_job_id = pub_jobs |> Enum.random() |> Map.get(:id)
      random_job_id2 = pub_jobs2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_job_id))
      assert results.entries |> Enum.any?(&(&1.id == random_job_id2))
    end
  end

  describe "[Accounts Publised repos]" do
    test "fresh user get empty paged published repos", ~m(user)a do
      {:ok, results} = Accounts.published_contents(user, :repo, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published repos", ~m(user user2 community community2)a do
      pub_repos =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          repo_attrs = mock_attrs(:repo, %{community_id: community.id})
          {:ok, repo} = CMS.create_content(community, :repo, repo_attrs, user)

          acc ++ [repo]
        end)

      pub_repos2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          repo_attrs = mock_attrs(:repo, %{community_id: community2.id})
          {:ok, repo} = CMS.create_content(community, :repo, repo_attrs, user)

          acc ++ [repo]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        repo_attrs = mock_attrs(:repo, %{community_id: community.id})
        {:ok, repo} = CMS.create_content(community, :repo, repo_attrs, user2)

        acc ++ [repo]
      end)

      {:ok, results} = Accounts.published_contents(user, :repo, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_repo_id = pub_repos |> Enum.random() |> Map.get(:id)
      random_repo_id2 = pub_repos2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_repo_id))
      assert results.entries |> Enum.any?(&(&1.id == random_repo_id2))
    end
  end
end
