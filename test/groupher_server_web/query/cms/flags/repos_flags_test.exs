defmodule GroupherServer.Test.Query.Flags.ReposFlags do
  use GroupherServer.TestTools

  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS

  @total_count 35
  @page_size get_config(:general, :page_size)

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, community} = db_insert(:community)

    {:ok, community2} = db_insert(:community)
    CMS.create_article(community2, :repo, mock_attrs(:repo), user)

    repos =
      Enum.reduce(1..@total_count, [], fn _, acc ->
        {:ok, value} = CMS.create_article(community, :repo, mock_attrs(:repo), user)
        acc ++ [value]
      end)

    repo_b = repos |> List.first()
    repo_m = repos |> Enum.at(div(@total_count, 2))
    repo_e = repos |> List.last()

    guest_conn = simu_conn(:guest)

    {:ok, ~m(guest_conn community user repo_b repo_m repo_e)a}
  end

  describe "[query repos flags]" do
    @query """
    query($filter: PagedReposFilter!) {
      pagedRepos(filter: $filter) {
        entries {
          id
          isPinned
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

    test "if have pinned repos, the pinned repos should at the top of entries",
         ~m(guest_conn community repo_m)a do
      variables = %{filter: %{community: community.raw}}
      # variables = %{filter: %{}}

      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      assert results |> is_valid_pagination?
      assert results["pageSize"] == @page_size
      assert results["totalCount"] == @total_count

      {:ok, _pined_repo} = CMS.pin_article(:repo, repo_m.id, community.id)

      results = guest_conn |> query_result(@query, variables, "pagedRepos")
      entries_first = results["entries"] |> List.first()

      assert results["totalCount"] == @total_count
      assert entries_first["id"] == to_string(repo_m.id)
      assert entries_first["isPinned"] == true
    end

    test "pind repos should not appear when page > 1", ~m(guest_conn community)a do
      variables = %{filter: %{page: 2, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")
      assert results |> is_valid_pagination?

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")

      {:ok, _pined_repo} = CMS.pin_article(:repo, random_id, community.id)

      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
    end

    test "if have trashed repos, the mark deleted repos should not appears in result",
         ~m(guest_conn community)a do
      variables = %{filter: %{community: community.raw}}
      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      random_id = results["entries"] |> Enum.shuffle() |> List.first() |> Map.get("id")
      {:ok, _} = CMS.mark_delete_article(:repo, random_id)

      results = guest_conn |> query_result(@query, variables, "pagedRepos")

      assert results["entries"] |> Enum.any?(&(&1["id"] !== random_id))
      assert results["totalCount"] == @total_count - 1
    end
  end
end
