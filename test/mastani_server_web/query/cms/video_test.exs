defmodule MastaniServer.Test.Query.VideoTest do
  use MastaniServer.TestTools

  setup do
    {:ok, video} = db_insert(:video)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn video)a}
  end

  @query """
  query($id: ID!) {
    video(id: $id) {
      id
      title
    }
  }
  """
  test "basic graphql query on video by user", ~m(guest_conn video)a do
    variables = %{id: video.id}
    results = guest_conn |> query_result(@query, variables, "video")

    assert results["id"] == to_string(video.id)
    assert is_valid_kv?(results, "title", :string)
    assert length(Map.keys(results)) == 2
  end

  @query """
  query($id: ID!) {
    video(id: $id) {
      views
    }
  }
  """
  test "views should +1 after query the video", ~m(user_conn video)a do
    variables = %{id: video.id}
    views_1 = user_conn |> query_result(@query, variables, "video") |> Map.get("views")

    variables = %{id: video.id}
    views_2 = user_conn |> query_result(@query, variables, "video") |> Map.get("views")
    assert views_2 == views_1 + 1
  end
end
