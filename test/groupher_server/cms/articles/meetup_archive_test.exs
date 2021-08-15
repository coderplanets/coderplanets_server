defmodule GroupherServer.Test.CMS.MeetupArchive do
  @moduledoc false
  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Repo}
  alias CMS.Model.Meetup

  @now Timex.now()
  @archive_threshold get_config(:article, :archive_threshold)
  @meetup_archive_threshold Timex.shift(
                              @now,
                              @archive_threshold[:meetup] || @archive_threshold[:default]
                            )

  @last_month Timex.shift(@now, days: -31, seconds: -1)

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, meetup} = db_insert(:meetup)
    {:ok, community} = db_insert(:community)

    {:ok, meetup_long_ago} = db_insert(:meetup, %{title: "last month", inserted_at: @last_month})
    db_insert_multi(:meetup, 5)

    {:ok, ~m(user community meetup_long_ago)a}
  end

  describe "[cms meetup archive]" do
    test "can archive meetups", ~m(meetup_long_ago)a do
      {:ok, _} = CMS.archive_articles(:meetup)

      archived_meetups =
        Meetup
        |> where([article], article.inserted_at < ^@meetup_archive_threshold)
        |> Repo.all()

      assert length(archived_meetups) == 1
      archived_meetup = archived_meetups |> List.first()
      assert archived_meetup.id == meetup_long_ago.id
    end

    test "can not edit archived meetup" do
      {:ok, _} = CMS.archive_articles(:meetup)

      archived_meetups =
        Meetup
        |> where([article], article.inserted_at < ^@meetup_archive_threshold)
        |> Repo.all()

      archived_meetup = archived_meetups |> List.first()
      {:error, reason} = CMS.update_article(archived_meetup, %{"title" => "new title"})
      assert reason |> is_error?(:archived)
    end

    test "can not delete archived meetup" do
      {:ok, _} = CMS.archive_articles(:meetup)

      archived_meetups =
        Meetup
        |> where([article], article.inserted_at < ^@meetup_archive_threshold)
        |> Repo.all()

      archived_meetup = archived_meetups |> List.first()

      {:error, reason} = CMS.mark_delete_article(:meetup, archived_meetup.id)
      assert reason |> is_error?(:archived)
    end
  end
end
