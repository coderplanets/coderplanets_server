defmodule GroupherServer.Test.Query.PagedArticles.PagedGuide do
  @moduledoc false
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]
  import Ecto.Query, warn: false

  alias GroupherServer.CMS
  alias GroupherServer.Repo

  alias CMS.Model.Guide

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

    {:ok, guide_last_week} =
      db_insert(:guide, %{title: "last week", inserted_at: @last_week, active_at: @last_week})

    db_insert(:guide, %{title: "last month", inserted_at: @last_month})

    {:ok, guide_last_year} =
      db_insert(:guide, %{title: "last year", inserted_at: @last_year, active_at: @last_year})

    db_insert_multi(:guide, @today_count)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user guide_last_week guide_last_year)a}
  end

  describe "[query paged_guides filter pagination]" do
    @query """
    query($filter: PagedGuideFilter!) {
      pagedGuides(filter: $filter) {
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
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == 10
      assert results["totalCount"] == @total_count
      assert results["entries"] |> List.first() |> Map.get("articleTags") |> is_list
    end

    test "should get valid thread document", ~m(guest_conn)a do
      {:ok, user} = db_insert(:user)
      {:ok, community} = db_insert(:community)
      guide_attrs = mock_attrs(:guide, %{community_id: community.id})
      Process.sleep(2000)
      {:ok, _guide} = CMS.create_article(community, :guide, guide_attrs, user)

      variables = %{filter: %{page: 1, size: 30}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      guide = results["entries"] |> List.first()
      assert not is_nil(get_in(guide, ["document", "bodyHtml"]))
    end

    test "support article_tag filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      guide_attrs = mock_attrs(:guide, %{community_id: community.id})
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, _} = CMS.set_article_tag(:guide, guide.id, article_tag.id)

      variables = %{filter: %{page: 1, size: 10, article_tag: article_tag.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      variables = %{filter: %{page: 1, size: 10, article_tags: [article_tag.raw]}}
      results2 = guest_conn |> query_result(@query, variables, "pagedGuides")
      assert results == results2

      guide = results["entries"] |> List.first()
      assert results["totalCount"] == 1
      assert exist_in?(article_tag, guide["articleTags"])
    end

    test "support multi-tag (article_tags) filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      guide_attrs = mock_attrs(:guide, %{community_id: community.id})
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      article_tag_attrs = mock_attrs(:article_tag)

      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, article_tag2} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, article_tag3} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)

      {:ok, _} = CMS.set_article_tag(:guide, guide.id, article_tag.id)
      {:ok, _} = CMS.set_article_tag(:guide, guide.id, article_tag2.id)

      variables = %{
        filter: %{page: 1, size: 10, article_tags: [article_tag.raw, article_tag2.raw]}
      }

      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      guide = results["entries"] |> List.first()
      assert results["totalCount"] == 1
      assert exist_in?(article_tag, guide["articleTags"])
      assert exist_in?(article_tag2, guide["articleTags"])
      assert not exist_in?(article_tag3, guide["articleTags"])
    end

    test "should not have pined guides when filter have article_tag or article_tags",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      guide_attrs = mock_attrs(:guide, %{community_id: community.id})
      {:ok, pinned_guide} = CMS.create_article(community, :guide, guide_attrs, user)
      {:ok, guide} = CMS.create_article(community, :guide, guide_attrs, user)

      {:ok, _} = CMS.pin_article(:guide, pinned_guide.id, community.id)

      article_tag_attrs = mock_attrs(:article_tag)
      {:ok, article_tag} = CMS.create_article_tag(community, :guide, article_tag_attrs, user)
      {:ok, _} = CMS.set_article_tag(:guide, guide.id, article_tag.id)

      variables = %{
        filter: %{page: 1, size: 10, community: community.raw, article_tag: article_tag.raw}
      }

      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      assert not exist_in?(pinned_guide, results["entries"])
      assert exist_in?(guide, results["entries"])

      variables = %{
        filter: %{page: 1, size: 10, community: community.raw, article_tags: [article_tag.raw]}
      }

      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      assert not exist_in?(pinned_guide, results["entries"])
      assert exist_in?(guide, results["entries"])
    end

    test "support community filter", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)

      guide_attrs = mock_attrs(:guide, %{community_id: community.id})
      {:ok, _guide} = CMS.create_article(community, :guide, guide_attrs, user)
      guide_attrs2 = mock_attrs(:guide, %{community_id: community.id})
      {:ok, _guide} = CMS.create_article(community, :guide, guide_attrs2, user)

      variables = %{filter: %{page: 1, size: 10, community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      guide = results["entries"] |> List.first()
      assert results["totalCount"] == 2
      assert exist_in?(%{id: to_string(community.id)}, guide["communities"])
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
      results = guest_conn |> query_result(@query, variables, "pagedGuides")
      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count
    end
  end

  describe "[query paged_guides filter has_xxx]" do
    @query """
    query($filter: PagedGuideFilter!) {
      pagedGuides(filter: $filter) {
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

      {:ok, guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)
      {:ok, _guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)
      {:ok, _guide3} = CMS.create_article(community, :guide, mock_attrs(:guide), user)

      variables = %{filter: %{community: community.raw}}
      results = user_conn |> query_result(@query, variables, "pagedGuides")
      assert results["totalCount"] == 3

      the_guide = Enum.find(results["entries"], &(&1["id"] == to_string(guide.id)))
      assert not the_guide["viewerHasViewed"]
      assert not the_guide["viewerHasUpvoted"]
      assert not the_guide["viewerHasCollected"]
      assert not the_guide["viewerHasReported"]

      {:ok, _} = CMS.read_article(:guide, guide.id, user)
      {:ok, _} = CMS.upvote_article(:guide, guide.id, user)
      {:ok, _} = CMS.collect_article(:guide, guide.id, user)
      {:ok, _} = CMS.report_article(:guide, guide.id, "reason", "attr_info", user)

      results = user_conn |> query_result(@query, variables, "pagedGuides")
      the_guide = Enum.find(results["entries"], &(&1["id"] == to_string(guide.id)))
      assert the_guide["viewerHasViewed"]
      assert the_guide["viewerHasUpvoted"]
      assert the_guide["viewerHasCollected"]
      assert the_guide["viewerHasReported"]
    end
  end

  describe "[query paged_guides filter sort]" do
    @query """
    query($filter: PagedGuideFilter!) {
      pagedGuides(filter: $filter) {
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

    test "filter community should get guides which belongs to that community",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      assert length(results["entries"]) == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(guide.id)))
    end

    test "should have a active_at same with inserted_at", ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, _guide} = CMS.create_article(community, :guide, mock_attrs(:guide), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")
      guide = results["entries"] |> List.first()

      assert guide["inserted_at"] == guide["active_at"]
    end

    test "filter sort should have default :desc_active", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")
      active_timestamps = results["entries"] |> Enum.map(& &1["active_at"])

      {:ok, first_active_time, 0} = active_timestamps |> List.first() |> DateTime.from_iso8601()
      {:ok, last_active_time, 0} = active_timestamps |> List.last() |> DateTime.from_iso8601()

      assert :gt = DateTime.compare(first_active_time, last_active_time)
    end

    @query """
    query($filter: PagedGuideFilter!) {
      pagedGuides(filter: $filter) {
        entries {
          id
          views
        }
      }
    }
    """

    test "filter sort MOST_VIEWS should work", ~m(guest_conn)a do
      most_views_guide = Guide |> order_by(desc: :views) |> limit(1) |> Repo.one()
      variables = %{filter: %{sort: "MOST_VIEWS"}}

      results = guest_conn |> query_result(@query, variables, "pagedGuides")
      find_guide = results |> Map.get("entries") |> hd

      assert find_guide["views"] == most_views_guide |> Map.get(:views)
    end
  end

  # TODO test  sort, tag, community, when ...
  @doc """
  test: FILTER when [TODAY] [THIS_WEEK] [THIS_MONTH] [THIS_YEAR]
  """
  describe "[query paged_guides filter when]" do
    @query """
    query($filter: PagedGuideFilter!) {
      pagedGuides(filter: $filter) {
        entries {
          id
          views
          inserted_at
        }
        totalCount
      }
    }
    """
    test "THIS_YEAR option should work", ~m(guest_conn guide_last_year)a do
      variables = %{filter: %{when: "THIS_YEAR"}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      assert results["entries"] |> Enum.any?(&(&1["id"] != guide_last_year.id))
    end

    test "TODAY option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "TODAY"}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      expect_count = @total_count - @last_year_count - @last_month_count - @last_week_count

      assert results |> Map.get("totalCount") == expect_count
    end

    test "THIS_WEEK option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_WEEK"}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      assert results |> Map.get("totalCount") == @today_count
    end

    test "THIS_MONTH option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_MONTH"}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

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

  describe "[query paged_guides filter extra]" do
    @query """
    query($filter: PagedGuideFilter!) {
      pagedGuides(filter: $filter) {
        entries {
          id
          title
        }
        totalCount
      }
    }
    """
    test "basic filter should work", ~m(guest_conn)a do
      {:ok, guide} = db_insert(:guide)
      {:ok, guide2} = db_insert(:guide)

      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")

      assert results["totalCount"] >= 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(guide.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] != to_string(guide2.id)))
    end
  end

  describe "[paged guides active_at]" do
    @query """
    query($filter: PagedGuideFilter!) {
      pagedGuides(filter: $filter) {
        entries {
          id
          insertedAt
          activeAt
        }
      }
    }
    """

    test "latest commented guide should appear on top", ~m(guest_conn guide_last_week user)a do
      variables = %{filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedGuides")
      entries = results["entries"]
      first_guide = entries |> List.first()
      assert first_guide["id"] !== to_string(guide_last_week.id)

      Process.sleep(1500)
      {:ok, _comment} = CMS.create_comment(:guide, guide_last_week.id, mock_comment(), user)

      results = guest_conn |> query_result(@query, variables, "pagedGuides")
      entries = results["entries"]
      first_guide = entries |> List.first()

      assert first_guide["id"] == to_string(guide_last_week.id)
    end

    test "comment on very old guide have no effect", ~m(guest_conn guide_last_year user)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, _comment} = CMS.create_comment(:guide, guide_last_year.id, mock_comment(), user)

      results = guest_conn |> query_result(@query, variables, "pagedGuides")
      entries = results["entries"]
      first_guide = entries |> List.first()

      assert first_guide["id"] !== to_string(guide_last_year.id)
    end

    test "latest guide author commented guide have no effect", ~m(guest_conn guide_last_week)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, _comment} =
        CMS.create_comment(
          :guide,
          guide_last_week.id,
          mock_comment(),
          guide_last_week.author.user
        )

      results = guest_conn |> query_result(@query, variables, "pagedGuides")
      entries = results["entries"]
      first_guide = entries |> List.first()

      assert first_guide["id"] !== to_string(guide_last_week.id)
    end
  end
end
