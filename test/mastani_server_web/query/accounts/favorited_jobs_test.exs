defmodule MastaniServer.Test.Query.Accounts.FavritedJobs do
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
    query($userId: ID, $categoryId: ID,$filter: PagedFilter!) {
      favoritedJobs(userId: $userId, categoryId: $categoryId, filter: $filter) {
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

    alias MastaniServer.Accounts

    test "can get paged favoritedJobs on a spec category", ~m(user_conn guest_conn jobs)a do
      {:ok, user} = db_insert(:user)

      Enum.each(jobs, fn job ->
        {:ok, _} = CMS.reaction(:job, :favorite, job.id, user)
      end)

      job1 = Enum.at(jobs, 0)
      job2 = Enum.at(jobs, 1)
      job3 = Enum.at(jobs, 2)
      job4 = Enum.at(jobs, 4)

      test_category = "test category"
      test_category2 = "test category2"

      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, category2} = Accounts.create_favorite_category(user, %{title: test_category2})

      {:ok, _favorites_category} = Accounts.set_favorites(user, :job, job1.id, category.id)
      {:ok, _favorites_category} = Accounts.set_favorites(user, :job, job2.id, category.id)
      {:ok, _favorites_category} = Accounts.set_favorites(user, :job, job3.id, category.id)
      {:ok, _favorites_category} = Accounts.set_favorites(user, :job, job4.id, category2.id)

      variables = %{userId: user.id, categoryId: category.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedJobs")
      results2 = guest_conn |> query_result(@query, variables, "favoritedJobs")

      assert results["totalCount"] == 3
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job1.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job2.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(job3.id)))

      assert results == results2
    end
  end
end
