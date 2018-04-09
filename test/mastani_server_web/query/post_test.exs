defmodule MastaniServer.Test.Query.PostTest do
  # use MastaniServer.DataCase
  use MastaniServerWeb.ConnCase, async: true
  import MastaniServer.Factory
  import MastaniServer.Test.ConnBuilder
  import MastaniServer.Test.AssertHelper
  import ShortMaps

  # alias MastaniServer.Accounts

  setup do
    {:ok, post} = db_insert(:post)

    guest_conn = mock_conn(:guest)
    user_conn = mock_conn(:user)

    {:ok, ~m(user_conn guest_conn post)a}
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
  test "basic graphql query on post with logined user", ~m(user_conn post)a do
    variables = %{id: post.id}
    results = user_conn |> query_result(@query, variables, "post")

    assert results["id"] == to_string(post.id)
    assert is_valid_kv?(results, "title", :string)
    assert is_valid_kv?(results, "body", :string)
    assert length(Map.keys(results)) == 3
  end

  test "basic graphql query on post with stranger(unloged user)", ~m(guest_conn post)a do
    variables = %{id: post.id}
    results = guest_conn |> query_result(@query, variables, "post")

    assert results["id"] == to_string(post.id)
    assert is_valid_kv?(results, "title", :string)
    assert is_valid_kv?(results, "body", :string)
  end

  @query """
  query Post($id: ID!) {
    post(id: $id) {
      id
      favoritedUsers {
        nickname
        id
      }
    }
  }
  """
  test "post have favoritedUsers query field", ~m(user_conn post)a do
    variables = %{id: post.id}
    results = user_conn |> query_result(@query, variables, "post")

    assert results["id"] == to_string(post.id)
    assert is_valid_kv?(results, "favoritedUsers", :list)
  end

  @query """
  query Post($id: ID!) {
    post(id: $id) {
      views
    }
  }
  """
  test "views should +1 after query the post", ~m(user_conn post)a do
    variables_1 = %{id: post.id}
    views_1 = user_conn |> query_result(@query, variables_1, "post") |> Map.get("views")

    variables_2 = %{id: post.id}
    views_2 = user_conn |> query_result(@query, variables_2, "post") |> Map.get("views")
    assert views_2 == views_1 + 1
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
  test "logged user can query viewerHasFavorited field", ~m(user_conn post)a do
    variables = %{id: post.id}

    assert user_conn
           |> query_result(@query, variables, "post")
           |> has_boolen_value?("viewerHasFavorited")
  end

  test "unlogged user can not query viewerHasFavorited field", ~m(guest_conn post)a do
    variables = %{id: post.id}

    assert guest_conn |> query_get_error?(@query, variables)
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
  test "logged user can query viewerHasStarred field", ~m(user_conn post)a do
    variables = %{id: post.id}

    assert user_conn
           |> query_result(@query, variables, "post")
           |> has_boolen_value?("viewerHasStarred")
  end

  test "unlogged user can not query viewerHasStarred field", ~m(guest_conn post)a do
    variables = %{id: post.id}
    assert guest_conn |> query_get_error?(@query, variables)
  end
end
