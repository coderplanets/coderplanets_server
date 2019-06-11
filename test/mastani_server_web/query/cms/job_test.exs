defmodule GroupherServer.Test.Query.Job do
  use GroupherServer.TestTools

  setup do
    {:ok, job} = db_insert(:job)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn job)a}
  end

  @query """
  query($id: ID!) {
    job(id: $id) {
      id
      title
      body
    }
  }
  """
  test "basic graphql query on job with logined user", ~m(user_conn job)a do
    variables = %{id: job.id}
    results = user_conn |> query_result(@query, variables, "job")

    assert results["id"] == to_string(job.id)
    assert is_valid_kv?(results, "title", :string)
    assert is_valid_kv?(results, "body", :string)
    assert length(Map.keys(results)) == 3
  end

  test "basic graphql query on job with stranger(unloged user)", ~m(guest_conn job)a do
    variables = %{id: job.id}
    results = guest_conn |> query_result(@query, variables, "job")

    assert results["id"] == to_string(job.id)
    assert is_valid_kv?(results, "title", :string)
    assert is_valid_kv?(results, "body", :string)
  end

  @query """
  query($id: ID!) {
    job(id: $id) {
      id
      favoritedUsers {
        nickname
        id
      }
    }
  }
  """
  test "job have favoritedUsers query field", ~m(user_conn job)a do
    variables = %{id: job.id}
    results = user_conn |> query_result(@query, variables, "job")

    assert results["id"] == to_string(job.id)
    assert is_valid_kv?(results, "favoritedUsers", :list)
  end

  @query """
  query($id: ID!) {
    job(id: $id) {
      id
      title
      body
      viewerHasFavorited
    }
  }
  """
  test "logged user can query viewerHasFavorited field", ~m(user_conn job)a do
    variables = %{id: job.id}

    assert user_conn
           |> query_result(@query, variables, "job")
           |> has_boolen_value?("viewerHasFavorited")
  end

  test "unlogged user can not query viewerHasFavorited field", ~m(guest_conn job)a do
    variables = %{id: job.id}

    assert guest_conn |> query_get_error?(@query, variables)
  end

  alias GroupherServer.Accounts

  @query """
  query($id: ID!) {
    job(id: $id) {
      id
      favoritedCategoryId
    }
  }
  """
  test "login user can get nil job favorited category id", ~m(job)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = %{id: job.id}
    result = user_conn |> query_result(@query, variables, "job")
    assert result["favoritedCategoryId"] == nil
  end

  test "login user can get job favorited category id after favorited", ~m(job)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    test_category = "test category"
    {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
    {:ok, _favorite_category} = Accounts.set_favorites(user, :job, job.id, category.id)

    variables = %{id: job.id}
    result = user_conn |> query_result(@query, variables, "job")

    assert result["favoritedCategoryId"] == to_string(category.id)
  end
end
