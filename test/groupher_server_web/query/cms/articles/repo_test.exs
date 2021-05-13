defmodule GroupherServer.Test.Query.Articles.Repo do
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
end
