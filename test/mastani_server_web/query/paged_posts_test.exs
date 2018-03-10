defmodule MastaniServer.Query.PagedPostsTest do
  # use MastaniServerWeb.ConnCase, async: true
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.AssertHelper

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
  test "get full pagination info", %{conn: conn} do
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
  test "pagination has default page and size arg", %{conn: conn} do
    variables = %{filter: %{}}
    results = conn |> query_get_result_of(@query, variables, "pagedPosts")
    # IO.inspect(results, label: "ff ")
    assert results |> is_valid_pagination?
    assert results["pageSize"] == 20
    assert results["totalCount"] == @posts_count
  end

  #TODO test sort, when ...
end
