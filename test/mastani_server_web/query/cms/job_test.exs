defmodule MastaniServer.Test.Query.Job do
  use MastaniServer.TestTools

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

  # @query """
  # query($id: ID!) {
  # job(id: $id) {
  # id
  # favoritedUsers {
  # nickname
  # id
  # }
  # }
  # }
  # """
  # test "post have favoritedUsers query field", ~m(user_conn job)a do
  # variables = %{id: job.id}
  # results = user_conn |> query_result(@query, variables, "job")

  # assert results["id"] == to_string(job.id)
  # assert is_valid_kv?(results, "favoritedUsers", :list)
  # end

  # @query """
  # query Post($id: ID!) {
  # post(id: $id) {
  # views
  # }
  # }
  # """
  # test "views should +1 after query the post", ~m(user_conn post)a do
  # variables = %{id: post.id}
  # views_1 = user_conn |> query_result(@query, variables, "post") |> Map.get("views")

  # variables = %{id: post.id}
  # views_2 = user_conn |> query_result(@query, variables, "post") |> Map.get("views")
  # assert views_2 == views_1 + 1
  # end

  # @query """
  # query Post($id: ID!) {
  # post(id: $id) {
  # id
  # title
  # body
  # viewerHasFavorited
  # }
  # }
  # """
  # test "logged user can query viewerHasFavorited field", ~m(user_conn post)a do
  # variables = %{id: post.id}

  # assert user_conn
  # |> query_result(@query, variables, "post")
  # |> has_boolen_value?("viewerHasFavorited")
  # end

  # test "unlogged user can not query viewerHasFavorited field", ~m(guest_conn post)a do
  # variables = %{id: post.id}

  # assert guest_conn |> query_get_error?(@query, variables)
  # end

  # @query """
  # query Post($id: ID!) {
  # post(id: $id) {
  # id
  # title
  # body
  # viewerHasStarred
  # }
  # }
  # """
  # test "logged user can query viewerHasStarred field", ~m(user_conn post)a do
  # variables = %{id: post.id}

  # assert user_conn
  # |> query_result(@query, variables, "post")
  # |> has_boolen_value?("viewerHasStarred")
  # end

  # test "unlogged user can not query viewerHasStarred field", ~m(guest_conn post)a do
  # variables = %{id: post.id}
  # assert guest_conn |> query_get_error?(@query, variables)
  # end
end
