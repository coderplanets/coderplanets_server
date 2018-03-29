defmodule MastaniServer.Test.Query.PagedPostsTest do
  # use MastaniServerWeb.ConnCase, async: true
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.Test.AssertHelper
  import Ecto.Query, warn: false

  alias MastaniServer.CMS
  alias MastaniServer.Repo

  @cur_date Timex.now()
  @last_week Timex.shift(Timex.beginning_of_week(@cur_date), days: -1)
  @last_month Timex.shift(Timex.beginning_of_month(@cur_date), days: -1)
  @last_year Timex.shift(Timex.beginning_of_year(@cur_date), days: -1)

  @posts_today_count 35

  @posts_last_week_count 1
  @posts_last_month_count 1
  @posts_last_year_count 1

  @posts_total_count @posts_today_count + @posts_last_week_count + @posts_last_month_count +
                       @posts_last_year_count

  setup do
    # TODO: token
    db_insert_multi!(:post, @posts_today_count)
    db_insert(:post, %{title: "last week", inserted_at: @last_week})
    db_insert(:post, %{title: "last month", inserted_at: @last_month})
    db_insert(:post, %{title: "last year", inserted_at: @last_year})

    # conn =
    # build_conn()
    # |> put_req_header("authorization", "Bearer fake-token")
    conn_without_token = build_conn()

    {:ok, conn_without_token: conn_without_token}
  end

  describe "[query paged_posts filter pagination]" do
    @query """
    query PagedPosts($filter: PagedArticleFilter!) {
      pagedPosts(filter: $filter) {
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
    test "should get pagination info", %{conn_without_token: conn} do
      variables = %{filter: %{page: 1, size: 10}}
      results = conn |> query_result(@query, variables, "pagedPosts")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == 10
      assert results["totalCount"] == @posts_total_count
    end

    test "request large size fails", %{conn_without_token: conn} do
      variables = %{filter: %{page: 1, size: 200}}
      assert conn |> query_get_error?(@query, variables)
    end

    test "request 0 or neg-size fails", %{conn_without_token: conn} do
      variables_0 = %{filter: %{page: 1, size: 0}}
      variables_neg_1 = %{filter: %{page: 1, size: -1}}

      assert conn |> query_get_error?(@query, variables_0)
      assert conn |> query_get_error?(@query, variables_neg_1)
    end

    test "pagination should have default page and size arg", %{conn_without_token: conn} do
      variables = %{filter: %{}}
      results = conn |> query_result(@query, variables, "pagedPosts")
      assert results |> is_valid_pagination?
      assert results["pageSize"] == 20
      assert results["totalCount"] == @posts_total_count
    end
  end

  describe "[query paged_posts filter sort]" do
    @query """
    query PagedPosts($filter: PagedArticleFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          inserted_at
        }
       }
    }
    """
    test "filter sort should have default :desc_inserted", %{conn_without_token: conn} do
      variables = %{filter: %{}}
      results = conn |> query_result(@query, variables, "pagedPosts")
      inserted_timestamps = results["entries"] |> Enum.map(& &1["inserted_at"])

      {:ok, first_inserted_time, 0} =
        inserted_timestamps |> List.first() |> DateTime.from_iso8601()

      {:ok, last_inserted_time, 0} = inserted_timestamps |> List.last() |> DateTime.from_iso8601()

      assert :gt = DateTime.compare(first_inserted_time, last_inserted_time)
    end

    @query """
    query PagedPosts($filter: PagedArticleFilter!) {
      pagedPosts(filter: $filter) {
        entries {
          id
          views
        }
      }
    }
    """
    test "filter sort MOST_VIEWS should work", %{conn_without_token: conn} do
      most_views_post = CMS.Post |> order_by(desc: :views) |> limit(1) |> Repo.one()
      variables = %{filter: %{sort: "MOST_VIEWS"}}

      results = conn |> query_result(@query, variables, "pagedPosts")
      find_post = results |> Map.get("entries") |> hd

      # assert find_post["id"] == most_views_post |> Map.get(:id) |> to_string
      assert find_post["views"] == most_views_post |> Map.get(:views)
    end
  end

  # TODO test  sort, tag, community, when ...
  @doc """
  test: FILTER when [TODAY] [THIS_WEEK] [THIS_MONTH] [THIS_YEAR]
  """
  describe "[query paged_posts filter when]" do
    @query """
    query PagedPosts($filter: PagedArticleFilter!) {
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
    test "THIS_YEAR option should work", %{conn_without_token: conn} do
      variables = %{filter: %{when: "THIS_YEAR"}}
      results = conn |> query_result(@query, variables, "pagedPosts")

      expect_count = @posts_total_count - @posts_last_year_count
      assert results |> Map.get("totalCount") == expect_count
    end

    test "TODAY option should work", %{conn_without_token: conn} do
      variables = %{filter: %{when: "TODAY"}}
      results = conn |> query_result(@query, variables, "pagedPosts")

      expect_count =
        @posts_total_count - @posts_last_year_count - @posts_last_month_count -
          @posts_last_week_count

      assert results |> Map.get("totalCount") == expect_count
    end

    test "THIS_WEEK option should work", %{conn_without_token: conn} do
      variables = %{filter: %{when: "THIS_WEEK"}}
      results = conn |> query_result(@query, variables, "pagedPosts")
      assert results |> Map.get("totalCount") == @posts_today_count
    end

    test "THIS_MONTH option should work", %{conn_without_token: conn} do
      variables = %{filter: %{when: "THIS_MONTH"}}
      results = conn |> query_result(@query, variables, "pagedPosts")

      expect_count = @posts_total_count - @posts_last_year_count - @posts_last_month_count
      assert results |> Map.get("totalCount") == expect_count
    end
  end
end
