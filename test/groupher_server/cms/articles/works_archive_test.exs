defmodule GroupherServer.Test.CMS.WorksArchive do
  @moduledoc false
  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Repo}
  alias CMS.Model.Works

  @now Timex.now()
  @archive_threshold get_config(:article, :archive_threshold)
  @works_archive_threshold Timex.shift(
                             @now,
                             @archive_threshold[:works] || @archive_threshold[:default]
                           )

  @last_week Timex.shift(@now, days: -7, seconds: -1)

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, works} = db_insert(:works)
    {:ok, community} = db_insert(:community)

    {:ok, works_long_ago} = db_insert(:works, %{title: "last month", inserted_at: @last_week})
    db_insert_multi(:works, 5)

    {:ok, ~m(user community works_long_ago)a}
  end

  describe "[cms works archive]" do
    test "can archive works", ~m(works_long_ago)a do
      {:ok, _} = CMS.archive_articles(:works)

      archived_works =
        Works
        |> where([article], article.inserted_at < ^@works_archive_threshold)
        |> Repo.all()

      assert length(archived_works) == 1
      archived_works = archived_works |> List.first()
      assert archived_works.id == works_long_ago.id
    end

    test "can not edit archived works" do
      {:ok, _} = CMS.archive_articles(:works)

      archived_works =
        Works
        |> where([article], article.inserted_at < ^@works_archive_threshold)
        |> Repo.all()

      archived_works = archived_works |> List.first()
      {:error, reason} = CMS.update_article(archived_works, %{"title" => "new title"})
      assert reason |> is_error?(:archived)
    end

    test "can not delete archived works" do
      {:ok, _} = CMS.archive_articles(:works)

      archived_works =
        Works
        |> where([article], article.inserted_at < ^@works_archive_threshold)
        |> Repo.all()

      archived_works = archived_works |> List.first()

      {:error, reason} = CMS.mark_delete_article(:works, archived_works.id)
      assert reason |> is_error?(:archived)
    end
  end
end
