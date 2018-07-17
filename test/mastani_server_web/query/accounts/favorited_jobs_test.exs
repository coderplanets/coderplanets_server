defmodule MastaniServer.Test.Query.Accounts.FavritedJobsTest do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  setup do
    {:ok, user} = db_insert(:user)
    total_count = 20
    {:ok, jobs} = db_insert_multi(:job, total_count)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user total_count jobs)a}
  end

  describe "[accounts favorited jobs]" do
    @query """
    query($filter: PagedFilter!) {
      account {
        id
        favoritedJobs(filter: $filter) {
          entries {
            id
          }
          totalCount
        }
        favoritedJobsCount
      }
    }
    """
    test "login user can get it's own favoritedJobs", ~m(user_conn user total_count jobs)a do
      Enum.each(jobs, fn job ->
        {:ok, _} = CMS.reaction(:job, :favorite, job.id, user)
      end)

      random_id = jobs |> Enum.shuffle() |> List.first() |> Map.get(:id) |> to_string

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "account")
      # IO.inspect results, label: "hello"
      assert results["favoritedJobs"] |> Map.get("totalCount") == total_count
      assert results["favoritedJobsCount"] == total_count

      assert results["favoritedJobs"]
             |> Map.get("entries")
             |> Enum.any?(&(&1["id"] == random_id))
    end

    @query """
    query($userId: ID, $filter: PagedFilter!) {
      favoritedJobs(userId: $userId, filter: $filter) {
        entries {
          id
        }
        totalCount
      }
    }
    """
    test "other user can get other user's paged favoritedJobs",
         ~m(user_conn guest_conn total_count jobs)a do
      {:ok, user} = db_insert(:user)

      Enum.each(jobs, fn job ->
        {:ok, _} = CMS.reaction(:job, :favorite, job.id, user)
      end)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedJobs")
      results2 = guest_conn |> query_result(@query, variables, "favoritedJobs")

      assert results["totalCount"] == total_count
      assert results2["totalCount"] == total_count
    end

    test "login user can get self paged favoritedJobs", ~m(user_conn user total_count jobs)a do
      Enum.each(jobs, fn job ->
        {:ok, _} = CMS.reaction(:job, :favorite, job.id, user)
      end)

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedJobs")

      assert results["totalCount"] == total_count
    end
  end
end
