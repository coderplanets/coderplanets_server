defmodule MastaniServer.Test.Query.Account.Fans do
  use MastaniServer.TestTools

  alias MastaniServer.Accounts

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account followers]" do
    @query """
    query($userId: ID, $filter: PagedFilter!) {
      pagedFollowers(userId: $userId, filter: $filter) {
        entries {
          id
        }
        totalCount
      }
    }
    """
    test "login user can get it's own paged followers", ~m(user)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)
      {:ok, _followeer} = user3 |> Accounts.follow(user2)

      user2_conn = simu_conn(:user, user2)
      results = user2_conn |> query_result(@query, variables, "pagedFollowers")

      assert results |> Map.get("totalCount") == 2
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
    end

    test "login user can get other user's paged followers", ~m(guest_conn user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      variables = %{userId: user2.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedFollowers")

      assert results |> Map.get("totalCount") == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user.id)))
      true
    end

    @query """
    query($userId: ID, $filter: PagedFilter!) {
      pagedFollowings(userId: $userId, filter: $filter) {
        entries {
          id
        }
        totalCount
      }
    }
    """
    test "login user can get it's own paged followings", ~m(user_conn user)a do
      variables = %{filter: %{page: 1, size: 20}}

      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)
      {:ok, user4} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)
      {:ok, _followeer} = user |> Accounts.follow(user3)
      {:ok, _followeer} = user |> Accounts.follow(user4)

      results = user_conn |> query_result(@query, variables, "pagedFollowings")

      assert results |> Map.get("totalCount") == 3
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user2.id)))
    end

    test "login user can get other user's paged followings", ~m(guest_conn user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      variables = %{userId: user.id, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedFollowings")

      assert results |> Map.get("totalCount") == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user2.id)))
    end

    @query """
    query($id: ID!) {
      user(id: $id) {
        id
        followersCount
      }
    }
    """
    test "can get user's followersCount", ~m(user_conn user)a do
      total_count = 15
      {:ok, users} = db_insert_multi(:user, total_count)

      Enum.each(users, fn other_user ->
        {:ok, _} = other_user |> Accounts.follow(user)
      end)

      variables = %{id: user.id}
      resolts = user_conn |> query_result(@query, variables, "user")

      assert resolts |> Map.get("followersCount") == total_count
    end

    @query """
    query($id: ID!) {
      user(id: $id) {
        id
        followingsCount
      }
    }
    """
    test "can get user's followingsCount", ~m(user_conn user)a do
      total_count = 15
      {:ok, users} = db_insert_multi(:user, total_count)

      Enum.each(users, fn cool_user ->
        {:ok, _} = user |> Accounts.follow(cool_user)
      end)

      # make some noise
      {:ok, [user2, user3]} = db_insert_multi(:user, 2)
      {:ok, _} = user2 |> Accounts.follow(user3)

      variables = %{id: user.id}
      resolts = user_conn |> query_result(@query, variables, "user")
      assert resolts |> Map.get("followingsCount") == total_count
    end

    @query """
    query($id: ID!) {
      user(id: $id) {
        id
        viewerHasFollowed
      }
    }
    """
    test "login user can check if 'i' has followed this user", ~m(user_conn user)a do
      {:ok, user2} = db_insert(:user)

      variables = %{id: user2.id}
      resolts = user_conn |> query_result(@query, variables, "user")
      assert resolts |> Map.get("viewerHasFollowed") == false

      {:ok, _} = user |> Accounts.follow(user2)
      variables = %{id: user2.id}
      resolts = user_conn |> query_result(@query, variables, "user")

      assert resolts |> Map.get("viewerHasFollowed") == true
    end
  end
end
