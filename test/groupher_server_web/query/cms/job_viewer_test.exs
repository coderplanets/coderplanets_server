defmodule GroupherServer.Test.Query.JobViewer do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.CMS

  setup do
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)
    {:ok, job} = CMS.create_content(community, :job, mock_attrs(:job), user)
    # noise
    {:ok, job2} = CMS.create_content(community, :job, mock_attrs(:job), user)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn community job job2)a}
  end

  @query """
  query($id: ID!) {
    job(id: $id) {
      views
    }
  }
  """
  test "guest user views should +1 after query the job", ~m(guest_conn job)a do
    variables = %{id: job.id}
    views_1 = guest_conn |> query_result(@query, variables, "job") |> Map.get("views")

    variables = %{id: job.id}
    views_2 = guest_conn |> query_result(@query, variables, "job") |> Map.get("views")
    assert views_2 == views_1 + 1
  end

  test "login views should +1 after query the job", ~m(user_conn job)a do
    variables = %{id: job.id}
    views_1 = user_conn |> query_result(@query, variables, "job") |> Map.get("views")

    variables = %{id: job.id}
    views_2 = user_conn |> query_result(@query, variables, "job") |> Map.get("views")
    assert views_2 == views_1 + 1
  end

  test "login views be record only once in job viewers", ~m(job)a do
    {:ok, user} = db_insert(:user)
    user_conn = simu_conn(:user, user)

    assert {:error, _} = ORM.find_by(CMS.JobViewer, %{job_id: job.id, user_id: user.id})

    variables = %{id: job.id}
    user_conn |> query_result(@query, variables, "job") |> Map.get("views")
    assert {:ok, viewer} = ORM.find_by(CMS.JobViewer, %{job_id: job.id, user_id: user.id})
    assert viewer.job_id == job.id
    assert viewer.user_id == user.id

    variables = %{id: job.id}
    user_conn |> query_result(@query, variables, "job") |> Map.get("views")
    assert {:ok, _} = ORM.find_by(CMS.JobViewer, %{job_id: job.id, user_id: user.id})
    assert viewer.job_id == job.id
    assert viewer.user_id == user.id
  end

  @paged_query """
  query($filter: PagedJobsFilter!) {
    pagedJobs(filter: $filter) {
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
    job(id: $id) {
      id
      views
      viewerHasViewed
    }
  }
  """
  test "user get has viewed flag after query/read the job", ~m(user_conn community job)a do
    variables = %{filter: %{community: community.raw}}
    results = user_conn |> query_result(@paged_query, variables, "pagedJobs")
    found = Enum.find(results["entries"], &(&1["id"] == to_string(job.id)))
    assert found["viewerHasViewed"] == false

    variables = %{id: job.id}
    result = user_conn |> query_result(@query, variables, "job")
    assert result["viewerHasViewed"] == true

    # noise: test viewer dataloader
    {:ok, user2} = db_insert(:user)
    user_conn2 = simu_conn(:user, user2)
    variables = %{filter: %{community: community.raw}}
    results = user_conn2 |> query_result(@paged_query, variables, "pagedJobs")
    found = Enum.find(results["entries"], &(&1["id"] == to_string(job.id)))
    assert found["viewerHasViewed"] == false

    variables = %{filter: %{community: community.raw}}
    results = user_conn |> query_result(@paged_query, variables, "pagedJobs")

    found = Enum.find(results["entries"], &(&1["id"] == to_string(job.id)))
    assert found["viewerHasViewed"] == true
  end
end
