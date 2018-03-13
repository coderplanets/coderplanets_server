defmodule MastaniServer.Query.PagedPostsTest do
  # use MastaniServerWeb.ConnCase, async: true
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.AssertHelper
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

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer fake-token")
      |> put_req_header("content-type", "application/json")

    conn_without_token = build_conn()
    # |> put_req_header("content-type", "application/json")
    {:ok, conn: conn, conn_without_token: conn_without_token}
  end

  @query """
  query PagedPosts($page: Int!, $size: Int!) {
    pagedPosts(filter: {page: $page, size: $size}) {
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
  test "should get pagination info", %{conn: conn} do
    variables = %{page: 1, size: 10}
    results = conn |> query_get_result_of(@query, variables, "pagedPosts")

    assert results |> is_valid_pagination?
    assert results["pageSize"] == 10
    assert results["totalCount"] == @posts_total_count
  end

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
  test "pagination should have default page and size arg", %{conn: conn} do
    variables = %{filter: %{}}
    results = conn |> query_get_result_of(@query, variables, "pagedPosts")
    # IO.inspect(results, label: "ff ")
    assert results |> is_valid_pagination?
    assert results["pageSize"] == 20
    assert results["totalCount"] == @posts_total_count
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
  test "filter sort MOST_VIEWS should work", %{conn: conn} do
    most_views_post = CMS.Post |> order_by(desc: :views) |> limit(1) |> Repo.one()
    variables = %{filter: %{sort: "MOST_VIEWS"}}

    results = conn |> query_get_result_of(@query, variables, "pagedPosts")
    find_post = results |> Map.get("entries") |> hd

    assert find_post["id"] == most_views_post |> Map.get(:id) |> to_string
    assert find_post["views"] == most_views_post |> Map.get(:views)
  end

  # TODO test  sort, tag, community, when ...
  @doc """
  test: filter when [TODAY] [THIS_WEEK] [THIS_MONTH] [THIS_YEAR]
  """
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
  test "filter when TODAY should work", %{conn: conn} do
    variables = %{filter: %{when: "TODAY"}}
    results = conn |> query_get_result_of(@query, variables, "pagedPosts")

    expect_count =
      @posts_total_count - @posts_last_year_count - @posts_last_month_count -
        @posts_last_week_count

    assert results |> Map.get("totalCount") == expect_count
  end

  test "filter when THIS_WEEK should work", %{conn: conn} do
    variables = %{filter: %{when: "THIS_WEEK"}}
    results = conn |> query_get_result_of(@query, variables, "pagedPosts")
    assert results |> Map.get("totalCount") == @posts_today_count
  end

  test "filter when THIS_MONTH should work", %{conn: conn} do
    variables = %{filter: %{when: "THIS_MONTH"}}
    results = conn |> query_get_result_of(@query, variables, "pagedPosts")

    expect_count = @posts_total_count - @posts_last_year_count - @posts_last_month_count
    assert results |> Map.get("totalCount") == expect_count
  end

  test "filter when THIS_YEAR should work", %{conn: conn} do
    variables = %{filter: %{when: "THIS_YEAR"}}
    results = conn |> query_get_result_of(@query, variables, "pagedPosts")

    expect_count = @posts_total_count - @posts_last_year_count
    assert results |> Map.get("totalCount") == expect_count
  end
end
