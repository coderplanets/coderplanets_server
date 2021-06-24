defmodule GroupherServer.Test.Query.Articles.Job do
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
    }
  }
  """
  test "basic graphql query on job with logined user", ~m(user_conn job)a do
    variables = %{id: job.id}
    results = user_conn |> query_result(@query, variables, "job")

    assert results["id"] == to_string(job.id)
    assert is_valid_kv?(results, "title", :string)
    assert length(Map.keys(results)) == 2
  end

  test "basic graphql query on job with stranger(unloged user)", ~m(guest_conn job)a do
    variables = %{id: job.id}
    results = guest_conn |> query_result(@query, variables, "job")

    assert results["id"] == to_string(job.id)
    assert is_valid_kv?(results, "title", :string)
  end
end
