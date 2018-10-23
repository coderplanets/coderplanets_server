defmodule MastaniServer.Test.Query.Video do
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

  alias MastaniServer.Accounts

  @query """
  query($id: ID!) {
    video(id: $id) {
      id
      favoritedCategoryId
    }
  }
  """
  test "login user can get nil video favorited category id", ~m(video)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    variables = %{id: video.id}
    result = user_conn |> query_result(@query, variables, "video")
    assert result["favoritedCategoryId"] == nil
  end

  test "login user can get video favorited category id after favorited", ~m(video)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    test_category = "test category"
    {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
    {:ok, _favorite_category} = Accounts.set_favorites(user, :video, video.id, category.id)

    variables = %{id: video.id}
    result = user_conn |> query_result(@query, variables, "video")

    assert result["favoritedCategoryId"] == to_string(category.id)
  end
end
