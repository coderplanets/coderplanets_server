defmodule GroupherServer.Test.CMS.Artilces.JobPin do
  @moduledoc false

  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  alias CMS.Model.{Community, PinnedArticle}

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, job} = CMS.create_article(community, :job, mock_attrs(:job), user)

    {:ok, ~m(user community job)a}
  end

  describe "[cms job pin]" do
    test "can pin a job", ~m(community job)a do
      {:ok, _} = CMS.pin_article(:job, job.id, community.id)
      {:ok, pind_article} = ORM.find_by(PinnedArticle, %{job_id: job.id})

      assert pind_article.job_id == job.id
    end

    test "one community & thread can only pin certern count of job", ~m(community user)a do
      Enum.reduce(1..@max_pinned_article_count_per_thread, [], fn _, acc ->
        {:ok, new_job} = CMS.create_article(community, :job, mock_attrs(:job), user)
        {:ok, _} = CMS.pin_article(:job, new_job.id, community.id)
        acc
      end)

      {:ok, new_job} = CMS.create_article(community, :job, mock_attrs(:job), user)
      {:error, reason} = CMS.pin_article(:job, new_job.id, community.id)
      assert reason |> Keyword.get(:code) == ecode(:too_much_pinned_article)
    end

    test "can not pin a non-exsit job", ~m(community)a do
      assert {:error, _} = CMS.pin_article(:job, 8848, community.id)
    end

    test "can undo pin to a job", ~m(community job)a do
      {:ok, _} = CMS.pin_article(:job, job.id, community.id)

      assert {:ok, unpinned} = CMS.undo_pin_article(:job, job.id, community.id)

      assert {:error, _} = ORM.find_by(PinnedArticle, %{job_id: job.id})
    end
  end
end
