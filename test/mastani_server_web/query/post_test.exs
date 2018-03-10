defmodule MastaniServer.Query.PostTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.AssertHelper
  alias MastaniServer.Accounts

  setup do
    {:ok, post} = db_insert(:post)

    # TODO: token
    db_insert(:user, %{
      username: "mydearxym",
      nickname: "mydearxym",
      bio: "mydearxym",
      company: "fake "
    })

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer fake-token")
      |> put_req_header("content-type", "application/json")

    conn_without_token = build_conn()
    # |> put_req_header("content-type", "application/json")
    {:ok, post: post, conn: conn, conn_without_token: conn_without_token}
  end

  @query """
  query Post($id: ID!) {
    post(id: $id) {
      id
      title
      body
    }
  }
  """
  test "basic graphql query on post with logined user", %{post: post, conn: conn} do
    # conn = build_conn()
    variables = %{id: post.id}
    results = conn |> query_get_result_of(@query, variables, "post")

    assert results["id"] == to_string(post.id)
    assert is_valid_key?(results, "title", :string)
    assert is_valid_key?(results, "body", :string)
    assert length(Map.keys(results)) == 3
  end

  test "basic graphql query on post with stranger(unloged user)", %{
    post: post,
    conn_without_token: conn_without_token
  } do
    # conn = build_conn()
    variables = %{id: post.id}
    results = conn_without_token |> query_get_result_of(@query, variables, "post")

    assert results["id"] == to_string(post.id)
    assert is_valid_key?(results, "title", :string)
    assert is_valid_key?(results, "body", :string)
  end

  @query """
  query Post($id: ID!) {
    post(id: $id) {
      id
      title
      body
      viewerHasFavorited
    }
  }
  """
  test "logged user can query viewerHasFavorited field", %{
    post: post,
    conn: conn
  } do
    variables = %{id: post.id}

    assert conn
           |> query_get_result_of(@query, variables, "post")
           |> has_boolen_value?("viewerHasFavorited")
  end

  test "unlogged user can not query viewerHasFavorited field", %{
    post: post,
    conn_without_token: conn_without_token
  } do
    variables = %{id: post.id}

    assert conn_without_token |> query_get_error?(@query, variables)
  end

  @query """
  query Post($id: ID!) {
    post(id: $id) {
      id
      title
      body
      viewerHasStarred
    }
  }
  """
  test "logged user can query viewerHasStarred field", %{
    post: post,
    conn: conn
  } do
    variables = %{id: post.id}

    assert conn
           |> query_get_result_of(@query, variables, "post")
           |> has_boolen_value?("viewerHasStarred")
  end

  test "unlogged user can not query viewerHasStarred field", %{
    post: post,
    conn_without_token: conn_without_token
  } do
    variables = %{id: post.id}
    assert conn_without_token |> query_get_error?(@query, variables)
  end
end
