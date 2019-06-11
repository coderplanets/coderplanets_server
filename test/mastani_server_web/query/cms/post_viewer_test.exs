defmodule GroupherServer.Test.Query.PostViewer do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)
    {:ok, post} = CMS.create_content(community, :post, mock_attrs(:post), user)
    # noise
    {:ok, post2} = CMS.create_content(community, :post, mock_attrs(:post), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn community post post2)a}
  end

  @query """
  query($id: ID!) {
    post(id: $id) {
      views
    }
  }
  """
  test "guest user views should +1 after query the post", ~m(guest_conn post)a do
    variables = %{id: post.id}
    views_1 = guest_conn |> query_result(@query, variables, "post") |> Map.get("views")

    variables = %{id: post.id}
    views_2 = guest_conn |> query_result(@query, variables, "post") |> Map.get("views")
    assert views_2 == views_1 + 1
  end

  test "login views should +1 after query the post", ~m(user_conn post)a do
    variables = %{id: post.id}
    views_1 = user_conn |> query_result(@query, variables, "post") |> Map.get("views")

    variables = %{id: post.id}
    views_2 = user_conn |> query_result(@query, variables, "post") |> Map.get("views")
    assert views_2 == views_1 + 1
  end

  test "login views be record only once in post viewers", ~m(post)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    assert {:error, _} = ORM.find_by(CMS.PostViewer, %{post_id: post.id, user_id: user.id})

    variables = %{id: post.id}
    user_conn |> query_result(@query, variables, "post") |> Map.get("views")
    assert {:ok, viewer} = ORM.find_by(CMS.PostViewer, %{post_id: post.id, user_id: user.id})
    assert viewer.post_id == post.id
    assert viewer.user_id == user.id

    variables = %{id: post.id}
    user_conn |> query_result(@query, variables, "post") |> Map.get("views")
    assert {:ok, _} = ORM.find_by(CMS.PostViewer, %{post_id: post.id, user_id: user.id})
    assert viewer.post_id == post.id
    assert viewer.user_id == user.id
  end

  @paged_query """
  query($filter: PagedArticleFilter!) {
    pagedPosts(filter: $filter) {
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
    post(id: $id) {
      id
      views
      viewerHasViewed
    }
  }
  """
  test "user get has viewed flag after query/read the post", ~m(user_conn community post)a do
    variables = %{filter: %{community: community.raw}}
    results = user_conn |> query_result(@paged_query, variables, "pagedPosts")
    found = Enum.find(results["entries"], &(&1["id"] == to_string(post.id)))
    assert found["viewerHasViewed"] == false

    variables = %{id: post.id}
    result = user_conn |> query_result(@query, variables, "post")
    assert result["viewerHasViewed"] == true

    # noise: test viewer dataloader
    {:ok, user2} = db_insert(:user)
    user_conn2 = simu_conn(:user, user2)
    variables = %{filter: %{community: community.raw}}
    results = user_conn2 |> query_result(@paged_query, variables, "pagedPosts")
    found = Enum.find(results["entries"], &(&1["id"] == to_string(post.id)))
    assert found["viewerHasViewed"] == false

    variables = %{filter: %{community: community.raw}}
    results = user_conn |> query_result(@paged_query, variables, "pagedPosts")

    found = Enum.find(results["entries"], &(&1["id"] == to_string(post.id)))
    assert found["viewerHasViewed"] == true
  end
end
