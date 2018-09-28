defmodule MastaniServer.Test.Query.Repo do
  use MastaniServer.TestTools

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
    }
  }
  """
  test "basic graphql query on repo by user", ~m(guest_conn repo)a do
    variables = %{id: repo.id}
    results = guest_conn |> query_result(@query, variables, "repo")

    assert results["id"] == to_string(repo.id)
    assert is_valid_kv?(results, "title", :string)
    assert length(Map.keys(results)) == 2
  end

  @query """
  query($id: ID!) {
    repo(id: $id) {
      views
    }
  }
  """
  test "views should +1 after query the repo", ~m(user_conn repo)a do
    variables = %{id: repo.id}
    views_1 = user_conn |> query_result(@query, variables, "repo") |> Map.get("views")

    variables = %{id: repo.id}
    views_2 = user_conn |> query_result(@query, variables, "repo") |> Map.get("views")
    assert views_2 == views_1 + 1
  end
end
