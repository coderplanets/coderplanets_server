defmodule GroupherServer.Test.Query.PagedArticles.PagedPosts do
  @moduledoc false

  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS
  alias GroupherServer.Repo

  alias CMS.Post

  @page_size get_config(:general, :page_size)

  @cur_date Timex.now()
  @last_week Timex.shift(Timex.beginning_of_week(@cur_date), days: -1, microseconds: -1)
  @last_month Timex.shift(Timex.beginning_of_month(@cur_date), days: -1, microseconds: -1)
  @last_year Timex.shift(Timex.beginning_of_year(@cur_date), days: -3, microseconds: -1)

  @today_count 15

  @last_week_count 1
  @last_month_count 1
  @last_year_count 1

  @total_count @today_count + @last_week_count + @last_month_count + @last_year_count

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, post_last_month} = db_insert(:post, %{title: "last month", inserted_at: @last_month})
    {:ok, post1} = db_insert(:post, %{title: "last week", inserted_at: @last_week})
    {:ok, post_last_year} = db_insert(:post, %{title: "last year", inserted_at: @last_year})

    db_insert_multi(:post, @today_count)

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn user post1 post_last_month post_last_year)a}
  end

  describe "[query paged_posts filter pagination]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          communities {
            raw
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
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

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
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count
    end
  end

  describe "[query paged_posts filter sort]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
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
    test "filter community should get posts which belongs to that community",
         ~m(guest_conn user)a do
      {:ok, community} = db_insert(:community)
      {:ok, post} = CMS.create_content(community, :post, mock_attrs(:post), user)

      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert length(results["entries"]) == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(post.id)))
    end

    @tag :skip_travis
    test "filter sort should have default :desc_inserted", ~m(guest_conn)a do
      variables = %{filter: %{}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      inserted_timestamps = results["entries"] |> Enum.map(& &1["inserted_at"])
      # IO.inspect(inserted_timestamps, label: "inserted_timestamps")

      {:ok, first_inserted_time, 0} =
        inserted_timestamps |> List.first() |> DateTime.from_iso8601()

      {:ok, last_inserted_time, 0} = inserted_timestamps |> List.last() |> DateTime.from_iso8601()

      assert :gt = DateTime.compare(first_inserted_time, last_inserted_time)
    end

    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          views
        }
      }
    }
    """
    test "filter sort MOST_VIEWS should work", ~m(guest_conn)a do
      most_views_post = Post |> order_by(desc: :views) |> limit(1) |> Repo.one()
      variables = %{filter: %{sort: "MOST_VIEWS"}}

      results = guest_conn |> query_result(@query, variables, "pagedPosts")
      find_post = results |> Map.get("entries") |> hd

      # assert find_post["id"] == most_views_post |> Map.get(:id) |> to_string
      assert find_post["views"] == most_views_post |> Map.get(:views)
    end
  end

  describe "[query paged_posts filter has_xxx]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
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

      {:ok, post} = CMS.create_content(community, :post, mock_attrs(:post), user)
      {:ok, _post2} = CMS.create_content(community, :post, mock_attrs(:post), user)
      {:ok, _post3} = CMS.create_content(community, :post, mock_attrs(:post), user)

      variables = %{filter: %{community: community.raw}}
      results = user_conn |> query_result(@query, variables, "pagedPosts")
      assert results["totalCount"] == 3

      the_post = Enum.find(results["entries"], &(&1["id"] == to_string(post.id)))
      assert not the_post["viewerHasViewed"]
      assert not the_post["viewerHasUpvoted"]
      assert not the_post["viewerHasCollected"]
      assert not the_post["viewerHasReported"]

      {:ok, _} = CMS.read_article(:post, post.id, user)
      {:ok, _} = CMS.upvote_article(:post, post.id, user)
      {:ok, _} = CMS.collect_article(:post, post.id, user)
      {:ok, _} = CMS.report_article(:post, post.id, "reason", "attr_info", user)

      results = user_conn |> query_result(@query, variables, "pagedPosts")
      the_post = Enum.find(results["entries"], &(&1["id"] == to_string(post.id)))
      assert the_post["viewerHasViewed"]
      assert the_post["viewerHasUpvoted"]
      assert the_post["viewerHasCollected"]
      assert the_post["viewerHasReported"]
    end
  end

  # TODO test  sort, tag, community, when ...
  @doc """
  test: FILTER when [TODAY] [THIS_WEEK] [THIS_MONTH] [THIS_YEAR]
  """
  describe "[query paged_posts filter when]" do
    @query """
    query($filter: PagedPostsFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          views
          inserted_at
        }
        totalCount
      }
    }
    """
    test "THIS_YEAR option should work", ~m(guest_conn post_last_year)a do
      variables = %{filter: %{when: "THIS_YEAR"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results["entries"] |> Enum.any?(&(&1["id"] != post_last_year.id))
    end

    test "TODAY option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "TODAY"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      expect_count = @total_count - @last_year_count - @last_month_count - @last_week_count

      assert results |> Map.get("totalCount") == expect_count
    end

    @tag :skip_travis
    test "THIS_WEEK option should work", ~m(guest_conn)a do
      variables = %{filter: %{when: "THIS_WEEK"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results |> Map.get("totalCount") == @today_count
    end

    test "THIS_MONTH option should work", ~m(guest_conn post_last_month)a do
      variables = %{filter: %{when: "THIS_MONTH"}}
      results = guest_conn |> query_result(@query, variables, "pagedPosts")

      assert results["entries"] |> Enum.any?(&(&1["id"] != post_last_month.id))
    end
  end
end
