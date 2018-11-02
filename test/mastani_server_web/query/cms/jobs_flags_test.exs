defmodule MastaniServer.Test.Query.JobsFlags do
  use MastaniServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias MastaniServer.CMS
  # alias MastaniServer.Repo

  alias CMS.Job

  @total_count 35
  @page_size get_config(:general, :page_size)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, community2} = db_insert(:community)
    CMS.create_content(community2, :job, mock_attrs(:job), user)

    jobs =
      Enum.reduce(1..@total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_content(community, :job, mock_attrs(:job), user)
        acc ++ [value]
      end)

    job_b = jobs |> List.first()
    job_m = jobs |> Enum.at(div(@total_count, 2))
    job_e = jobs |> List.last()

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user job_b job_m job_e)a}
  end

  describe "[query jobs flags]" do
    @query """
    query($filter: PagedArticleFilter!) {
      pagedJobs(filter: $filter) {
        entries {
          id
          pin
          communities {
            raw
          }
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    @tag :wip
    test "if have pined jobs, the pined jobs should at the top of entries",
         ~m(guest_conn community job_m)a do
      variables = %{filter: %{community: community.raw}}
      # variables = %{filter: %{}}

      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count

      {:ok, _pined_post} = CMS.pin_content(job_m, community)

      results = guest_conn |> query_result(@query, variables, "pagedJobs")
      entries_first = results["entries"] |> List.first()

      assert results["totalCount"] == @total_count + 1
      assert entries_first["id"] == to_string(job_m.id)
      assert entries_first["pin"] == true
    end

    @tag :wip
    test "pind jobs should not appear when page > 1", ~m(guest_conn community)a do
      variables = %{filter: %{page: 2, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")
      assert results |> is_valid_pagination?

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")
      {:ok, _pined_post} = CMS.pin_content(%Job{id: random_id}, community)
      # {:ok, _} = CMS.set_community_flags(%Job{id: random_id}, community.id, %{pin: true})
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
    end

    test "if have trashed jobs, the trashed jobs should not appears in result",
         ~m(guest_conn community)a do
      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")
      {:ok, _} = CMS.set_community_flags(%Job{id: random_id}, community.id, %{trash: true})

      results = guest_conn |> query_result(@query, variables, "pagedJobs")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
      assert results["totalCount"] == @total_count - 1
    end
  end
end
