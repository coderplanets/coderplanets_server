defmodule GroupherServer.Test.Query.Accounts.FavoriteCategory do
  use GroupherServer.TestTools

  alias GroupherServer.Accounts
  # alias Accounts.FavoriteCategory

  setup do
    {:ok, user} = db_insert(:user)
    {:ok, post} = db_insert(:post)

    user_conn = simu_conn(:user, user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user post)a}
  end

  describe "[Accounts FavoriteCategory]" do
    @query """
    query($userId: ID, $filter: CommonPagedFilter!) {
      favoriteCategories(userId: $userId, filter: $filter) {
        entries {
          id
          title
          private
        }
        totalPages
        totalCount
        pageSize
        pageNumber
      }
    }
    """
    test "user can get list of favorite categories", ~m(user user_conn)a do
      test_category = "test category"
      {:ok, _} = Accounts.create_favorite_category(user, %{title: test_category, private: false})

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoriteCategories")
      assert results |> is_valid_pagination?
      assert results["totalCount"] == 1
    end

    test "author can get it's own private categories", ~m(user user_conn)a do
      test_category = "test category"
      test_category2 = "test category2"
      {:ok, _} = Accounts.create_favorite_category(user, %{title: test_category, private: false})
      {:ok, _} = Accounts.create_favorite_category(user, %{title: test_category2, private: true})

      variables = %{filter: %{page: 1, size: 20}}
      results = user_conn |> query_result(@query, variables, "favoriteCategories")
      assert results |> is_valid_pagination?
      assert results["totalCount"] == 2
    end

    test "guest user can't get others private favorite categories", ~m(guest_conn)a do
      {:ok, user} = db_insert(:user)

      test_category = "test category"
      test_category2 = "test category2"
      {:ok, _} = Accounts.create_favorite_category(user, %{title: test_category, private: false})
      {:ok, _} = Accounts.create_favorite_category(user, %{title: test_category2, private: true})

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "favoriteCategories")
      assert results |> is_valid_pagination?

      assert results["entries"] |> Enum.any?(&(&1["title"] !== test_category2))
      assert results["totalCount"] == 1
    end
  end
end
