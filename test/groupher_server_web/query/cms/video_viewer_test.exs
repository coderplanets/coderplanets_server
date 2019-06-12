defmodule GroupherServer.Test.Query.VideoViewer do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)
    {:ok, video} = CMS.create_content(community, :video, mock_attrs(:video), user)
    # noise
    {:ok, video2} = CMS.create_content(community, :video, mock_attrs(:video), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn community video video2)a}
  end

  @query """
  query($id: ID!) {
  video(id: $id) {
      views
    }
  }
  """
  test "guest user views should +1 after query the video", ~m(guest_conn video)a do
    variables = %{id: video.id}
    views_1 = guest_conn |> query_result(@query, variables, "video") |> Map.get("views")

    variables = %{id: video.id}
    views_2 = guest_conn |> query_result(@query, variables, "video") |> Map.get("views")
    assert views_2 == views_1 + 1
  end

  test "login views should +1 after query the video", ~m(user_conn video)a do
    variables = %{id: video.id}
    views_1 = user_conn |> query_result(@query, variables, "video") |> Map.get("views")

    variables = %{id: video.id}
    views_2 = user_conn |> query_result(@query, variables, "video") |> Map.get("views")
    assert views_2 == views_1 + 1
  end

  test "login views be record only once in video viewers", ~m(video)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    assert {:error, _} = ORM.find_by(CMS.VideoViewer, %{video_id: video.id, user_id: user.id})

    variables = %{id: video.id}
    user_conn |> query_result(@query, variables, "video") |> Map.get("views")
    assert {:ok, viewer} = ORM.find_by(CMS.VideoViewer, %{video_id: video.id, user_id: user.id})
    assert viewer.video_id == video.id
    assert viewer.user_id == user.id

    variables = %{id: video.id}
    user_conn |> query_result(@query, variables, "video") |> Map.get("views")
    assert {:ok, _} = ORM.find_by(CMS.VideoViewer, %{video_id: video.id, user_id: user.id})
    assert viewer.video_id == video.id
    assert viewer.user_id == user.id
  end

  @paged_query """
  query($filter: PagedVideosFilter!) {
    pagedVideos(filter: $filter) {
      entries {
        id
        views
        viewerHasViewed
      }
    }
  }
  """

  @query """
  query($id: ID!) {
    video(id: $id) {
      id
      views
      viewerHasViewed
    }
  }
  """
  test "user get has viewed flag after query/read the video", ~m(user_conn community video)a do
    variables = %{filter: %{community: community.raw}}
    results = user_conn |> query_result(@paged_query, variables, "pagedVideos")
    found = Enum.find(results["entries"], &(&1["id"] == to_string(video.id)))
    assert found["viewerHasViewed"] == false

    variables = %{id: video.id}
    result = user_conn |> query_result(@query, variables, "video")
    assert result["viewerHasViewed"] == true

    # noise: test viewer dataloader
    {:ok, user2} = db_insert(:user)
    user_conn2 = simu_conn(:user, user2)
    variables = %{filter: %{community: community.raw}}
    results = user_conn2 |> query_result(@paged_query, variables, "pagedVideos")
    found = Enum.find(results["entries"], &(&1["id"] == to_string(video.id)))
    assert found["viewerHasViewed"] == false

    variables = %{filter: %{community: community.raw}}
    results = user_conn |> query_result(@paged_query, variables, "pagedVideos")

    found = Enum.find(results["entries"], &(&1["id"] == to_string(video.id)))
    assert found["viewerHasViewed"] == true
  end
end
