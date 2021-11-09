defmodule GroupherServer.Test.Query.PagedArticles.PagedWorks do
  @moduledoc false
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]
  import Ecto.Query, warn: false

  alias GroupherServer.CMS
  alias GroupherServer.Repo

  alias CMS.Model.Works

  @page_size get_config(:general, :page_size)

  @now Timex.now()
  @last_week Timex.shift(Timex.beginning_of_week(@now), days: -1, seconds: -1)
  @last_month Timex.shift(Timex.beginning_of_month(@now), days: -7, seconds: -1)
  @last_year Timex.shift(Timex.beginning_of_year(@now), days: -2, seconds: -1)

  @today_count 15

  @last_week_count 1
  @last_month_count 1
  @last_year_count 1

  @total_count @today_count + @last_week_count + @last_month_count + @last_year_count

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, works_last_week} =
      db_insert(:works, %{title: "last week", inserted_at: @last_week, active_at: @last_week})

    db_insert(:works, %{title: "last month", inserted_at: @last_month})

    {:ok, works_last_year} =
      db_insert(:works, %{title: "last year", inserted_at: @last_year, active_at: @last_year})

    db_insert_multi(:works, @today_count)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user works_last_week works_last_year)a}
  end

  describe "[query paged_works filter pagination]" do
    @query """
    query($filter: PagedWorksFilter!) {
      pagedWorks(filter: $filter) {
        entries {
          id
          document {
            bodyHtml
          }
          communities {
            id
            raw
          }
          articleTags {
            id
          }
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
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == 10
      assert results["totalCount"] == @total_count
      assert results["entries"] |> List.first() |> Map.get("articleTags") |> is_list
    end

    test "should get valid thread document", ~m(guest_conn)a do
      {:ok, user} = db_insert(:user)
      {:ok, community} = db_insert(:community)
      works_attrs = mock_attrs(:works, %{community_id: community.id})
      Process.sleep(2000)
      {:ok, _works} = CMS.create_article(community, :works, works_attrs, user)

      variables = %{filter: %{page: 1, size: 30}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      works = results["entries"] |> List.first()
      assert not is_nil(get_in(works, ["document", "bodyHtml"]))
    end

    test "support article_tag filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      works_attrs = mock_attrs(:works, %{community_id: community.id})
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, _} = CMS.set_article_tag(:works, works.id, article_tag.id)

      variables = %{filter: %{page: 1, size: 10, article_tag: article_tag.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      variables = %{filter: %{page: 1, size: 10, article_tags: [article_tag.raw]}}
      results2 = guest_conn |> query_result(@query, variables, "pagedWorks")
      assert results == results2

      works = results["entries"] |> List.first()
      assert results["totalCount"] == 1
      assert exist_in?(article_tag, works["articleTags"])
    end

    test "support multi-tag (article_tags) filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      works_attrs = mock_attrs(:works, %{community_id: community.id})
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, article_tag3} = CMS.create_article_tag(community, :works, article_tag_attrs, user)

      {:ok, _} = CMS.set_article_tag(:works, works.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:works, works.id, article_tag2.id)

      variables = %{
        filter: %{page: 1, size: 10, article_tags: [article_tag.raw, article_tag2.raw]}
      }

      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      works = results["entries"] |> List.first()
      assert results["totalCount"] == 1
      assert exist_in?(article_tag, works["articleTags"])
      assert exist_in?(article_tag2, works["articleTags"])
      assert not exist_in?(article_tag3, works["articleTags"])
    end

    test "should not have pined works when filter have article_tag or article_tags",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      works_attrs = mock_attrs(:works, %{community_id: community.id})
      {:ok, pinned_works} = CMS.create_article(community, :works, works_attrs, user)
      {:ok, works} = CMS.create_article(community, :works, works_attrs, user)

      {:ok, _} = CMS.pin_article(:works, pinned_works.id, community.id)

      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :works, article_tag_attrs, user)
      {:ok, _} = CMS.set_article_tag(:works, works.id, article_tag.id)

      variables = %{
        filter: %{page: 1, size: 10, community: community.raw, article_tag: article_tag.raw}
      }

      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      assert not exist_in?(pinned_works, results["entries"])
      assert exist_in?(works, results["entries"])

      variables = %{
        filter: %{page: 1, size: 10, community: community.raw, article_tags: [article_tag.raw]}
      }

      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      assert not exist_in?(pinned_works, results["entries"])
      assert exist_in?(works, results["entries"])
    end

    test "support community filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)

      works_attrs = mock_attrs(:works, %{community_id: community.id})
      {:ok, _works} = CMS.create_article(community, :works, works_attrs, user)
      works_attrs2 = mock_attrs(:works, %{community_id: community.id})
      {:ok, _works} = CMS.create_article(community, :works, works_attrs2, user)

      variables = %{filter: %{page: 1, size: 10, community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      works = results["entries"] |> List.first()
      assert results["totalCount"] == 2
      assert exist_in?(%{id: to_string(community.id)}, works["communities"])
    end

    test "request large size fails", ~m(guest_conn)a do
      variables = %{filter: %{page: 1, size: 200}}
      assert guest_conn |> query_get_error?(@query, variables, ecode(:pagination))
    end

    test "request 0 or neg-size fails", ~m(guest_conn)a do
      variables_0 = %{filter: %{page: 1, size: 0}}
      variables_neg_1 = %{filter: %{page: 1, size: -1}}

      assert guest_conn |> query_get_error?(@query, variables_0)
      assert guest_conn |> query_get_error?(@query, variables_neg_1)
    end

    test "pagination should have default page and size arg", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")
      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count
    end
  end

  describe "[query paged_works filter has_xxx]" do
    @query """
    query($filter: PagedWorksFilter!) {
      pagedWorks(filter: $filter) {
        entries {
          id
          viewerHasCollected
          viewerHasUpvoted
          viewerHasViewed
          viewerHasReported
        }
        totalCount
      }
    }
    """

    test "has_xxx state should work", ~m(user)a do
      user_conn = simu_conn(:user, user)
      {:ok, community} = db_insert(:community)

      {:ok, works} = CMS.create_article(community, :works, mock_attrs(:works), user)
      {:ok, _works} = CMS.create_article(community, :works, mock_attrs(:works), user)
      {:ok, _works3} = CMS.create_article(community, :works, mock_attrs(:works), user)

      variables = %{filter: %{community: community.raw}}
      results = user_conn |> query_result(@query, variables, "pagedWorks")
      assert results["totalCount"] == 3

      the_works = Enum.find(results["entries"], &(&1["id"] == to_string(works.id)))
      assert not the_works["viewerHasViewed"]
      assert not the_works["viewerHasUpvoted"]
      assert not the_works["viewerHasCollected"]
      assert not the_works["viewerHasReported"]

      {:ok, _} = CMS.read_article(:works, works.id, user)
      {:ok, _} = CMS.upvote_article(:works, works.id, user)
      {:ok, _} = CMS.collect_article(:works, works.id, user)
      {:ok, _} = CMS.report_article(:works, works.id, "reason", "attr_info", user)

      results = user_conn |> query_result(@query, variables, "pagedWorks")
      the_works = Enum.find(results["entries"], &(&1["id"] == to_string(works.id)))
      assert the_works["viewerHasViewed"]
      assert the_works["viewerHasUpvoted"]
      assert the_works["viewerHasCollected"]
      assert the_works["viewerHasReported"]
    end
  end

  describe "[query paged_works filter sort]" do
    @query """
    query($filter: PagedWorksFilter!) {
      pagedWorks(filter: $filter) {
        entries {
          id
          inserted_at
          active_at
          author {
            id
            nickname
            avatar
          }
        }
       }
    }
    """

    test "filter community should get works which belongs to that community",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, works} = CMS.create_article(community, :works, mock_attrs(:works), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      assert length(results["entries"]) == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(works.id)))
    end

    test "should have a active_at same with inserted_at", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, _works} = CMS.create_article(community, :works, mock_attrs(:works), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")
      works = results["entries"] |> List.first()

      assert works["inserted_at"] == works["active_at"]
    end

    test "filter sort should have default :desc_active", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")
      active_timestamps = results["entries"] |> Enum.map(& &1["active_at"])

      {:ok, first_active_time, 0} = active_timestamps |> List.first() |> DateTime.from_iso8601()
      {:ok, last_active_time, 0} = active_timestamps |> List.last() |> DateTime.from_iso8601()

      assert :gt = DateTime.compare(first_active_time, last_active_time)
    end

    @query """
    query($filter: PagedWorksFilter!) {
      pagedWorks(filter: $filter) {
        entries {
          id
          views
        }
      }
    }
    """

    test "filter sort MOST_VIEWS should work", ~m(guest_conn)a do
      most_views_works = Works |> order_by(desc: :views) |> limit(1) |> Repo.one()
      variables = %{filter: %{sort: "MOST_VIEWS"}}

      results = guest_conn |> query_result(@query, variables, "pagedWorks")
      find_works = results |> Map.get("entries") |> hd

      assert find_works["views"] == most_views_works |> Map.get(:views)
    end
  end

  # TODO test  sort, tag, community, when ...
  @doc """
  test: FILTER when [TODAY] [THIS_WEEK] [THIS_MONTH] [THIS_YEAR]
  """
  describe "[query paged_works filter when]" do
    @query """
    query($filter: PagedWorksFilter!) {
      pagedWorks(filter: $filter) {
        entries {
          id
          views
          inserted_at
        }
        totalCount
      }
    }
    """
    test "THIS_YEAR option should work", ~m(guest_conn works_last_year)a do
      variables = %{filter: %{when: "THIS_YEAR"}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      assert results["entries"] |> Enum.any?(&(&1["id"] != works_last_year.id))
    end

    test "TODAY option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "TODAY"}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      expect_count = @total_count - @last_year_count - @last_month_count - @last_week_count

      assert results |> Map.get("totalCount") == expect_count
    end

    test "THIS_WEEK option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_WEEK"}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      assert results |> Map.get("totalCount") == @today_count
    end

    test "THIS_MONTH option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_MONTH"}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      {_, cur_week_month, _} = @now |> Date.to_erl()
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

  describe "[query paged_works filter extra]" do
    @query """
    query($filter: PagedWorksFilter!) {
      pagedWorks(filter: $filter) {
        entries {
          id
          title
        }
        totalCount
      }
    }
    """
    test "basic filter should work", ~m(guest_conn)a do
      {:ok, works} = db_insert(:works)
      {:ok, works2} = db_insert(:works)

      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(works.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(works2.id)))
    end
  end

  describe "[paged works active_at]" do
    @query """
    query($filter: PagedWorksFilter!) {
      pagedWorks(filter: $filter) {
        entries {
          id
          insertedAt
          activeAt
        }
      }
    }
    """

    test "latest commented works should appear on top", ~m(guest_conn works_last_week user)a do
      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedWorks")
      entries = results["entries"]
      first_works = entries |> List.first()
      assert first_works["id"] !== to_string(works_last_week.id)

      Process.sleep(1500)
      {:ok, _comment} = CMS.create_comment(:works, works_last_week.id, mock_comment(), user)

      results = guest_conn |> query_result(@query, variables, "pagedWorks")
      entries = results["entries"]
      first_works = entries |> List.first()

      assert first_works["id"] == to_string(works_last_week.id)
    end

    test "comment on very old works have no effect", ~m(guest_conn works_last_year user)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, _comment} = CMS.create_comment(:works, works_last_year.id, mock_comment(), user)

      results = guest_conn |> query_result(@query, variables, "pagedWorks")
      entries = results["entries"]
      first_works = entries |> List.first()

      assert first_works["id"] !== to_string(works_last_year.id)
    end

    test "latest works author commented works have no effect", ~m(guest_conn works_last_week)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, _comment} =
        CMS.create_comment(
          :works,
          works_last_week.id,
          mock_comment(),
          works_last_week.author.user
        )

      results = guest_conn |> query_result(@query, variables, "pagedWorks")
      entries = results["entries"]
      first_works = entries |> List.first()

      assert first_works["id"] !== to_string(works_last_week.id)
    end
  end
end
