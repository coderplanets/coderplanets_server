defmodule GroupherServer.Test.Query.PagedVideos do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias GroupherServer.Repo

  alias CMS.Video

  @page_size get_config(:general, :page_size)

  @cur_date Timex.now()
  @last_week Timex.shift(Timex.beginning_of_week(@cur_date), days: -1, microseconds: -1)
  @last_month Timex.shift(Timex.beginning_of_month(@cur_date), days: -7, microseconds: -1)
  @last_year Timex.shift(Timex.beginning_of_year(@cur_date), days: -2, microseconds: -1)

  @today_count 15

  @last_week_count 1
  @last_month_count 1
  @last_year_count 1

  @total_count @today_count + @last_week_count + @last_month_count + @last_year_count

  setup do
    {:ok, user} = db_insert(:user)
    db_insert_multi(:video, @today_count)
    db_insert(:video, %{title: "last week", inserted_at: @last_week})
    db_insert(:video, %{title: "last month", inserted_at: @last_month})
    {:ok, video_last_year} = db_insert(:video, %{title: "last year", inserted_at: @last_year})

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user video_last_year)a}
  end

  describe "[query paged_videos filter pagination]" do
    @query """
    query($filter: PagedVideosFilter!) {
      pagedVideos(filter: $filter) {
        entries {
          id
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "should get pagination info", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 10}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == 10
      assert results["totalCount"] == @total_count
    end

    test "request large size fails", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 200}}
      assert guest_conn |> query_get_error?(@query, variables, ecode(:pagination))
    end

    test "request 0 or neg-size fails", ~m(guest_conn)a do
      variables_0 = %{filter: %{page: 1, size: 0}}
      variables_neg_1 = %{filter: %{page: 1, size: -1}}

      assert guest_conn |> query_get_error?(@query, variables_0, ecode(:pagination))
      assert guest_conn |> query_get_error?(@query, variables_neg_1, ecode(:pagination))
    end

    test "pagination should have default page and size arg", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")
      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count
    end
  end

  describe "[query paged_videos filter sort]" do
    @query """
    query($filter: PagedVideosFilter!) {
      pagedVideos(filter: $filter) {
        entries {
          id
          inserted_at
          author {
            id
            nickname
            avatar
          }
          communities {
            id
            raw
          }
        }
      }
    }
    """
    test "filter community should get videos which belongs to that community",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, video} = CMS.create_content(community, :video, mock_attrs(:video), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      assert length(results["entries"]) == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(video.id)))
    end

    @tag :skip_travis
    test "filter sort should have default :desc_inserted", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")
      inserted_timestamps = results["entries"] |> Enum.map(& &1["inserted_at"])

      {:ok, first_inserted_time, 0} =
        inserted_timestamps |> List.first() |> DateTime.from_iso8601()

      {:ok, last_inserted_time, 0} = inserted_timestamps |> List.last() |> DateTime.from_iso8601()

      assert :gt = DateTime.compare(first_inserted_time, last_inserted_time)
    end

    @query """
    query($filter: PagedVideosFilter!) {
      pagedVideos(filter: $filter) {
        entries {
          id
          views
        }
      }
    }
    """
    test "filter sort MOST_VIEWS should work", ~m(guest_conn)a do
      most_views_video = Video |> order_by(desc: :views) |> limit(1) |> Repo.one()
      variables = %{filter: %{sort: "MOST_VIEWS"}}

      results = guest_conn |> query_result(@query, variables, "pagedVideos")
      find_video = results |> Map.get("entries") |> hd

      assert find_video["views"] == most_views_video |> Map.get(:views)
    end
  end

  describe "[query paged_videos filter when]" do
    @query """
    query($filter: PagedVideosFilter!) {
      pagedVideos(filter: $filter) {
        entries {
          id
          views
          inserted_at
        }
        totalCount
      }
    }
    """
    test "THIS_YEAR option should work", ~m(guest_conn video_last_year)a do
      variables = %{filter: %{when: "THIS_YEAR"}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      assert results["entries"] |> Enum.any?(&(&1["id"] != video_last_year.id))
    end

    test "TODAY option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "TODAY"}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      expect_count = @total_count - @last_year_count - @last_month_count - @last_week_count

      assert results |> Map.get("totalCount") == expect_count
    end

    test "THIS_WEEK option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_WEEK"}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      assert results |> Map.get("totalCount") == @today_count
    end

    test "THIS_MONTH option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_MONTH"}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      {_, cur_week_month, _} = @cur_date |> Date.to_erl()
      {_, last_week_month, _} = @last_week |> Date.to_erl()

      expect_count =
        case cur_week_month == last_week_month do
          true ->
            @total_count - @last_year_count - @last_month_count

          false ->
            @total_count - @last_year_count - @last_month_count - @last_week_count
        end

      assert results |> Map.get("totalCount") == expect_count
    end
  end

  describe "[query paged_videos filter extra]" do
    @query """
    query($filter: PagedVideosFilter!) {
      pagedVideos(filter: $filter) {
        entries {
          id
          source
        }
        totalCount
      }
    }
    """
    test "source option should work", ~m(guest_conn)a do
      {:ok, video} = db_insert(:video, %{source: "youtube"})
      {:ok, video2} = db_insert(:video, %{source: "bilibil"})

      variables = %{filter: %{page: 1, size: 20, source: "youtube"}}
      results = guest_conn |> query_result(@query, variables, "pagedVideos")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.all?(&(&1["source"] == "youtube"))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(video.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(video2.id)))
    end
  end
end
