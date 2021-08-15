defmodule GroupherServer.Test.CMS.JobArchive do
  @moduledoc false
  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Repo}
  alias CMS.Model.Job

  @now Timex.now()
  @archive_threshold get_config(:article, :archive_threshold)
  @job_archive_threshold Timex.shift(
                           @now,
                           @archive_threshold[:job] || @archive_threshold[:default]
                         )

  @last_week Timex.shift(@now, days: -7, seconds: -1)

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, job} = db_insert(:job)
    {:ok, community} = db_insert(:community)

    {:ok, job_long_ago} = db_insert(:job, %{title: "last week", inserted_at: @last_week})
    db_insert_multi(:job, 5)

    {:ok, ~m(user community job_long_ago)a}
  end

  describe "[cms job archive]" do
    test "can archive jobs", ~m(job_long_ago)a do
      {:ok, _} = CMS.archive_articles(:job)

      archived_jobs =
        Job
        |> where([article], article.inserted_at < ^@job_archive_threshold)
        |> Repo.all()

      assert length(archived_jobs) == 1
      archived_job = archived_jobs |> List.first()
      assert archived_job.id == job_long_ago.id
    end

    test "can not edit archived job" do
      {:ok, _} = CMS.archive_articles(:job)

      archived_jobs =
        Job
        |> where([article], article.inserted_at < ^@job_archive_threshold)
        |> Repo.all()

      archived_job = archived_jobs |> List.first()
      {:error, reason} = CMS.update_article(archived_job, %{"title" => "new title"})
      assert reason |> is_error?(:archived)
    end

    test "can not delete archived job" do
      {:ok, _} = CMS.archive_articles(:job)

      archived_jobs =
        Job
        |> where([article], article.inserted_at < ^@job_archive_threshold)
        |> Repo.all()

      archived_job = archived_jobs |> List.first()

      {:error, reason} = CMS.mark_delete_article(:job, archived_job.id)
      assert reason |> is_error?(:archived)
    end
  end
end
