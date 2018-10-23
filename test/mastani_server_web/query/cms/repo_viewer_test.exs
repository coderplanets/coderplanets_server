defmodule MastaniServer.Test.Query.RepoViewer do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.CMS

  setup do
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)
    {:ok, repo} = CMS.create_content(community, :repo, mock_attrs(:repo), user)
    # noise
    {:ok, repo2} = CMS.create_content(community, :repo, mock_attrs(:repo), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn community repo repo2)a}
  end

  @query """
  query($id: ID!) {
  repo(id: $id) {
      views
    }
  }
  """
  @tag :wip
  test "guest user views should +1 after query the repo", ~m(guest_conn repo)a do
    variables = %{id: repo.id}
    views_1 = guest_conn |> query_result(@query, variables, "repo") |> Map.get("views")

    variables = %{id: repo.id}
    views_2 = guest_conn |> query_result(@query, variables, "repo") |> Map.get("views")
    assert views_2 == views_1 + 1
  end

  @tag :wip
  test "login views should +1 after query the repo", ~m(user_conn repo)a do
    variables = %{id: repo.id}
    views_1 = user_conn |> query_result(@query, variables, "repo") |> Map.get("views")

    variables = %{id: repo.id}
    views_2 = user_conn |> query_result(@query, variables, "repo") |> Map.get("views")
    assert views_2 == views_1 + 1
  end

  @tag :wip
  test "login views be record only once in repo viewers", ~m(repo)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    assert {:error, _} = ORM.find_by(CMS.RepoViewer, %{repo_id: repo.id, user_id: user.id})

    variables = %{id: repo.id}
    user_conn |> query_result(@query, variables, "repo") |> Map.get("views")
    assert {:ok, viewer} = ORM.find_by(CMS.RepoViewer, %{repo_id: repo.id, user_id: user.id})
    assert viewer.repo_id == repo.id
    assert viewer.user_id == user.id

    variables = %{id: repo.id}
    user_conn |> query_result(@query, variables, "repo") |> Map.get("views")
    assert {:ok, _} = ORM.find_by(CMS.RepoViewer, %{repo_id: repo.id, user_id: user.id})
    assert viewer.repo_id == repo.id
    assert viewer.user_id == user.id
  end

  @paged_query """
  query($filter: PagedArticleFilter!) {
    pagedRepos(filter: $filter) {
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
  repo(id: $id) {
      id
      views
      viewerHasViewed
    }
  }
  """
  @tag :wip
  test "user get has viewed flag after query/read the repo", ~m(user_conn community repo)a do
    variables = %{filter: %{community: community.raw}}
    results = user_conn |> query_result(@paged_query, variables, "pagedRepos")
    found = Enum.find(results["entries"], &(&1["id"] == to_string(repo.id)))
    assert found["viewerHasViewed"] == false

    variables = %{id: repo.id}
    result = user_conn |> query_result(@query, variables, "repo")
    assert result["viewerHasViewed"] == true

    variables = %{filter: %{community: community.raw}}
    results = user_conn |> query_result(@paged_query, variables, "pagedRepos")

    found = Enum.find(results["entries"], &(&1["id"] == to_string(repo.id)))
    assert found["viewerHasViewed"] == true
  end
end
