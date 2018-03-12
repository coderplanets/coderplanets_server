defmodule MastaniServer.Query.PagedPostsTest do
  # use MastaniServerWeb.ConnCase, async: true
  use MastaniServerWeb.ConnCase, async: true

  import MastaniServer.Factory
  import MastaniServer.AssertHelper
  import Ecto.Query, warn: false

  alias MastaniServer.CMS
  alias MastaniServer.Repo

  @posts_count 38

  setup do
    # TODO: token
    db_insert_multi!(:post, @posts_count)

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
    assert results["totalCount"] == @posts_count
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
    assert results["totalCount"] == @posts_count
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
    most_views_post = CMS.Post |> order_by(desc: :views) |> limit(1) |> Repo.one
    variables = %{filter: %{sort: "MOST_VIEWS"}}

    results = conn |> query_get_result_of(@query, variables, "pagedPosts")
    find_post = results |> Map.get("entries") |> hd

    assert find_post["id"] == most_views_post |> Map.get(:id) |> to_string
    assert find_post["views"] == most_views_post |> Map.get(:views)
  end

  #TODO test  sort, tag, community, when ...
end
