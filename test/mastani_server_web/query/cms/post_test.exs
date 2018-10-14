defmodule MastaniServer.Test.Query.Post do
  use MastaniServer.TestTools

  setup do
    {:ok, post} = db_insert(:post)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn post)a}
  end

  @query """
  query($id: ID!) {
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
  query($id: ID!) {
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
  query($id: ID!) {
    post(id: $id) {
      views
    }
  }
  """
  test "views should +1 after query the post", ~m(user_conn post)a do
    variables = %{id: post.id}
    views_1 = user_conn |> query_result(@query, variables, "post") |> Map.get("views")

    variables = %{id: post.id}
    views_2 = user_conn |> query_result(@query, variables, "post") |> Map.get("views")
    assert views_2 == views_1 + 1
  end

  @query """
  query($id: ID!) {
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

    assert guest_conn |> query_get_error?(@query, variables, ecode(:account_login))
  end

  @query """
  query($id: ID!) {
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
    assert guest_conn |> query_get_error?(@query, variables, ecode(:account_login))
  end

  alias MastaniServer.Accounts

  @query """
  query($id: ID!) {
    post(id: $id) {
      id
      favoritedCategoryId
    }
  }
  """
  test "login user can get nil post favorited category id", ~m(post)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = %{id: post.id}
    result = user_conn |> query_result(@query, variables, "post")
    assert result["favoritedCategoryId"] == nil
  end

  test "login user can get post favorited category id after favorited", ~m(post)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    test_category = "test category"
    {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
    {:ok, _favorite_category} = Accounts.set_favorites(user, :post, post.id, category.id)

    variables = %{id: post.id}
    result = user_conn |> query_result(@query, variables, "post")

    assert result["favoritedCategoryId"] == to_string(category.id)
  end
end
