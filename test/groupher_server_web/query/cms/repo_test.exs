defmodule GroupherServer.Test.Query.Repo do
  use GroupherServer.TestTools

  setup do
    {:ok, repo} = db_insert(:repo)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn repo)a}
  end

  @query """
  query($id: ID!) {
    repo(id: $id) {
      id
      title
      readme
    }
  }
  """
  test "basic graphql query on repo with logined user", ~m(user_conn repo)a do
    variables = %{id: repo.id}
    results = user_conn |> query_result(@query, variables, "repo")

    assert results["id"] == to_string(repo.id)
    assert is_valid_kv?(results, "title", :string)
    assert is_valid_kv?(results, "readme", :string)
    assert length(Map.keys(results)) == 3
  end

  test "basic graphql query on repo with stranger(unloged user)", ~m(guest_conn repo)a do
    variables = %{id: repo.id}
    results = guest_conn |> query_result(@query, variables, "repo")

    assert results["id"] == to_string(repo.id)
    assert is_valid_kv?(results, "title", :string)
    assert is_valid_kv?(results, "readme", :string)
  end

  @query """
  query($id: ID!) {
    repo(id: $id) {
      id
      favoritedUsers {
        nickname
        id
      }
    }
  }
  """
  test "repo have favoritedUsers query field", ~m(user_conn repo)a do
    variables = %{id: repo.id}
    results = user_conn |> query_result(@query, variables, "repo")

    assert results["id"] == to_string(repo.id)
    assert is_valid_kv?(results, "favoritedUsers", :list)
  end

  @query """
  query($id: ID!) {
    repo(id: $id) {
      id
      title
      viewerHasFavorited
      favoritedCount
    }
  }
  """
  test "logged user can query viewerHasFavorited field", ~m(user_conn repo)a do
    variables = %{id: repo.id}

    assert user_conn
           |> query_result(@query, variables, "repo")
           |> has_boolen_value?("viewerHasFavorited")
  end

  test "unlogged user can not query viewerHasFavorited field", ~m(guest_conn repo)a do
    variables = %{id: repo.id}

    assert guest_conn |> query_get_error?(@query, variables)
  end

  alias GroupherServer.Accounts

  @query """
  query($id: ID!) {
    repo(id: $id) {
      id
      favoritedCategoryId
    }
  }
  """
  test "login user can get nil repo favorited category id", ~m(repo)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = %{id: repo.id}
    result = user_conn |> query_result(@query, variables, "repo")
    assert result["favoritedCategoryId"] == nil
  end

  test "login user can get repo favorited category id after favorited", ~m(repo)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    test_category = "test category"
    {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
    {:ok, _favorite_category} = Accounts.set_favorites(user, :repo, repo.id, category.id)

    variables = %{id: repo.id}
    result = user_conn |> query_result(@query, variables, "repo")

    assert result["favoritedCategoryId"] == to_string(category.id)
  end
end
