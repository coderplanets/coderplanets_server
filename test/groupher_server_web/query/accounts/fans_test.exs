defmodule GroupherServer.Test.Query.Account.Fans do
  use GroupherServer.TestTools

  alias GroupherServer.Accounts

  setup do
    {:ok, user} = db_insert(:user)
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user, user)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account followers]" do
    @query """
    query($login: String!, $filter: PagedFilter!) {
      pagedFollowers(login: $login, filter: $filter) {
        entries {
          id
          viewerBeenFollowed
          viewerHasFollowed
        }
        totalCount
      }
    }
    """
    test "login user can get basic paged followers info", ~m(user)a do
      variables = %{login: user.login, filter: %{page: 1, size: 20}}

      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)

      {:ok, _} = Accounts.follow(user2, user)
      {:ok, _} = Accounts.follow(user3, user)

      user_conn = simu_conn(:user, user)
      results = user_conn |> query_result(@query, variables, "pagedFollowers")

      assert results |> Map.get("totalCount") == 2
      entries = results |> Map.get("entries")

      assert entries |> List.first() |> Map.get("viewerBeenFollowed")
      assert entries |> List.last() |> Map.get("viewerBeenFollowed")

      assert user2 |> exist_in?(entries)
      assert user3 |> exist_in?(entries)
    end

    test "login user can get other user's paged followers", ~m(guest_conn user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      variables = %{login: user2.login, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedFollowers")

      assert results |> Map.get("totalCount") == 1
      entries = results |> Map.get("entries")

      assert user |> exist_in?(entries)
    end

    @query """
    query($login: String!, $filter: PagedFilter!) {
      pagedFollowings(login: $login, filter: $filter) {
        entries {
          id
          viewerHasFollowed
        }
        totalCount
      }
    }
    """

    test "login user can get it's own paged followings", ~m(user_conn user)a do
      variables = %{login: user.login, filter: %{page: 1, size: 20}}

      {:ok, user2} = db_insert(:user)
      {:ok, user3} = db_insert(:user)
      {:ok, user4} = db_insert(:user)

      {:ok, _followeer} = user |> Accounts.follow(user2)
      {:ok, _followeer} = user |> Accounts.follow(user3)
      {:ok, _followeer} = user |> Accounts.follow(user4)

      results = user_conn |> query_result(@query, variables, "pagedFollowings")

      assert results |> Map.get("totalCount") == 3

      entries = results |> Map.get("entries")

      assert entries |> List.first() |> Map.get("viewerHasFollowed")
      assert entries |> List.last() |> Map.get("viewerHasFollowed")

      assert user2 |> exist_in?(entries)
      assert user3 |> exist_in?(entries)
      assert user4 |> exist_in?(entries)
    end

    test "login user can get other user's paged followings", ~m(guest_conn user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      variables = %{login: user.login, filter: %{page: 1, size: 20}}
      results = guest_conn |> query_result(@query, variables, "pagedFollowings")

      assert results |> Map.get("totalCount") == 1
      assert results["entries"] |> Enum.any?(&(&1["id"] == to_string(user2.id)))
    end

    @query """
    query($login: String!) {
      user(login: $login) {
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

      variables = %{login: user.login}
      resolts = user_conn |> query_result(@query, variables, "user")

      assert resolts |> Map.get("followersCount") == total_count
    end

    @query """
    query($login: String!) {
      user(login: $login) {
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

      variables = %{login: user.login}
      resolts = user_conn |> query_result(@query, variables, "user")
      assert resolts |> Map.get("followingsCount") == total_count
    end

    @query """
    query($login: String!) {
      user(login: $login) {
        id
        viewerHasFollowed
      }
    }
    """

    test "login user can check if 'i' has followed this user", ~m(user_conn user)a do
      {:ok, user2} = db_insert(:user)

      variables = %{login: user2.login}
      resolts = user_conn |> query_result(@query, variables, "user")
      assert resolts |> Map.get("viewerHasFollowed") == false

      {:ok, _} = user |> Accounts.follow(user2)
      variables = %{login: user2.login}
      resolts = user_conn |> query_result(@query, variables, "user")

      assert resolts |> Map.get("viewerHasFollowed") == true
    end

    @query """
    query($login: String!) {
      user(login: $login) {
        id
        viewerBeenFollowed
      }
    }
    """

    test "login user can check if 'i' was been followed", ~m(user)a do
      {:ok, user2} = db_insert(:user)
      user_conn = simu_conn(:user, user2)

      variables = %{login: user.login}
      resolts = user_conn |> query_result(@query, variables, "user")
      assert resolts |> Map.get("viewerBeenFollowed") == false

      {:ok, _} = Accounts.follow(user, user2)
      variables = %{login: user.login}

      resolts = user_conn |> query_result(@query, variables, "user")

      assert resolts |> Map.get("viewerBeenFollowed") == true
    end
  end
end
