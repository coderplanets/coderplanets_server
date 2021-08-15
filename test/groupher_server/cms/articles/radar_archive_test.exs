defmodule GroupherServer.Test.CMS.RadarArchive do
  @moduledoc false
  use GroupherServer.TestTools
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.{CMS, Repo}
  alias CMS.Model.Radar

  @now Timex.now()
  @archive_threshold get_config(:article, :archive_threshold)
  @radar_archive_threshold Timex.shift(
                             @now,
                             @archive_threshold[:radar] || @archive_threshold[:default]
                           )

  @last_week Timex.shift(@now, days: -7, seconds: -1)

  setup do
    {:ok, user} = db_insert(:user)
    # {:ok, radar} = db_insert(:radar)
    {:ok, community} = db_insert(:community)

    {:ok, radar_long_ago} = db_insert(:radar, %{title: "last week", inserted_at: @last_week})
    db_insert_multi(:radar, 5)

    {:ok, ~m(user community radar_long_ago)a}
  end

  describe "[cms radar archive]" do
    test "can archive radars", ~m(radar_long_ago)a do
      {:ok, _} = CMS.archive_articles(:radar)

      archived_radars =
        Radar
        |> where([article], article.inserted_at < ^@radar_archive_threshold)
        |> Repo.all()

      assert length(archived_radars) == 1
      archived_radar = archived_radars |> List.first()
      assert archived_radar.id == radar_long_ago.id
    end

    test "can not edit archived radar" do
      {:ok, _} = CMS.archive_articles(:radar)

      archived_radars =
        Radar
        |> where([article], article.inserted_at < ^@radar_archive_threshold)
        |> Repo.all()

      archived_radar = archived_radars |> List.first()
      {:error, reason} = CMS.update_article(archived_radar, %{"title" => "new title"})
      assert reason |> is_error?(:archived)
    end

    test "can not delete archived radar" do
      {:ok, _} = CMS.archive_articles(:radar)

      archived_radars =
        Radar
        |> where([article], article.inserted_at < ^@radar_archive_threshold)
        |> Repo.all()

      archived_radar = archived_radars |> List.first()

      {:error, reason} = CMS.mark_delete_article(:radar, archived_radar.id)
      assert reason |> is_error?(:archived)
    end
  end
end
