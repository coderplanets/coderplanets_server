defmodule MastaniServer.Test.Query.Accounts.FavritedRepos do
  use MastaniServer.TestTools

  alias MastaniServer.CMS

  @total_count 20

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, repos} = db_insert_multi(:repo, @total_count)

    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(guest_conn user_conn user repos)a}
  end

  describe "[accounts favorited repos]" do
    @query """
    query($filter: PagedFilter!) {
      account {
        id
        favoritedRepos(filter: $filter) {
          entries {
            id
          }
          totalCount
        }
        favoritedReposCount
      }
    }
    """
    test "login user can get it's own favoritedRepos", ~m(user_conn user repos)a do
      Enum.each(repos, fn repo ->
        {:ok, _} = CMS.reaction(:repo, :favorite, repo.id, user)
      end)

      random_id = repos |> Enum.shuffle() |> List.first() |> Map.get(:id) |> to_string

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "account")
      assert results["favoritedRepos"] |> Map.get("totalCount") == @total_count
      assert results["favoritedReposCount"] == @total_count

      assert results["favoritedRepos"]
             |> Map.get("entries")
             |> Enum.any?(&(&1["id"] == random_id))
    end

    @query """
    query($userId: ID!, $categoryId: ID,$filter: PagedFilter!) {
      favoritedRepos(userId: $userId, categoryId: $categoryId, filter: $filter) {
        entries {
          id
        }
        totalCount
      }
    }
    """
    test "other user can get other user's paged favoritedRepos",
         ~m(user_conn guest_conn repos)a do
      {:ok, user} = db_insert(:user)

      Enum.each(repos, fn repo ->
        {:ok, _} = CMS.reaction(:repo, :favorite, repo.id, user)
      end)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedRepos")
      results2 = guest_conn |> query_result(@query, variables, "favoritedRepos")

      assert results["totalCount"] == @total_count
      assert results2["totalCount"] == @total_count
    end

    test "login user can get self paged favoritedRepos", ~m(user_conn user repos)a do
      Enum.each(repos, fn repo ->
        {:ok, _} = CMS.reaction(:repo, :favorite, repo.id, user)
      end)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedRepos")

      assert results["totalCount"] == @total_count
    end

    alias MastaniServer.Accounts

    test "can get paged favoritedRepos on a spec category", ~m(user_conn guest_conn repos)a do
      {:ok, user} = db_insert(:user)

      Enum.each(repos, fn repo ->
        {:ok, _} = CMS.reaction(:repo, :favorite, repo.id, user)
      end)

      repo1 = Enum.at(repos, 0)
      repo2 = Enum.at(repos, 1)
      repo3 = Enum.at(repos, 2)
      repo4 = Enum.at(repos, 4)

      test_category = "test category"
      test_category2 = "test category2"

      {:ok, category} = Accounts.create_favorite_category(user, %{title: test_category})
      {:ok, category2} = Accounts.create_favorite_category(user, %{title: test_category2})

      {:ok, _favorites_category} = Accounts.set_favorites(user, :repo, repo1.id, category.id)
      {:ok, _favorites_category} = Accounts.set_favorites(user, :repo, repo2.id, category.id)
      {:ok, _favorites_category} = Accounts.set_favorites(user, :repo, repo3.id, category.id)
      {:ok, _favorites_category} = Accounts.set_favorites(user, :repo, repo4.id, category2.id)

      variables = %{userId: user.id, categoryId: category.id, filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoritedRepos")
      results2 = guest_conn |> query_result(@query, variables, "favoritedRepos")

      assert results["totalCount"] == 3
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(repo1.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(repo2.id)))
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(repo3.id)))

      assert results == results2
    end
  end
end
