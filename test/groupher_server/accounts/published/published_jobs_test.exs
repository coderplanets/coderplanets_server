defmodule GroupherServer.Test.Accounts.Published.Job do
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

  describe "[publised jobs]" do
    @tag :wip2
    test "create job should update user published meta", ~m(community user)a do
      job_attrs = mock_attrs(:job, %{community_id: community.id})
      {:ok, _job} = CMS.create_article(community, :job, job_attrs, user)
      {:ok, _job} = CMS.create_article(community, :job, job_attrs, user)

      {:ok, user} = ORM.find(User, user.id)
      assert user.meta.published_jobs_count == 2
    end

    test "fresh user get empty paged published jobs", ~m(user)a do
      {:ok, results} = Accounts.published_articles(user, :job, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == 0
    end

    test "user can get paged published jobs", ~m(user user2 community community2)a do
      pub_jobs =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          job_attrs = mock_attrs(:job, %{community_id: community.id})
          {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

          acc ++ [job]
        end)

      pub_jobs2 =
        Enum.reduce(1..@publish_count, [], fn _, acc ->
          job_attrs = mock_attrs(:job, %{community_id: community2.id})
          {:ok, job} = CMS.create_article(community, :job, job_attrs, user)

          acc ++ [job]
        end)

      # unrelated other user
      Enum.reduce(1..5, [], fn _, acc ->
        job_attrs = mock_attrs(:job, %{community_id: community.id})
        {:ok, job} = CMS.create_article(community, :job, job_attrs, user2)

        acc ++ [job]
      end)

      {:ok, results} = Accounts.published_articles(user, :job, %{page: 1, size: 20})

      assert results |> is_valid_pagination?(:raw)
      assert results.total_count == @publish_count * 2

      random_job_id = pub_jobs |> Enum.random() |> Map.get(:id)
      random_job_id2 = pub_jobs2 |> Enum.random() |> Map.get(:id)
      assert results.entries |> Enum.any?(&(&1.id == random_job_id))
      assert results.entries |> Enum.any?(&(&1.id == random_job_id2))
    end
  end
end
