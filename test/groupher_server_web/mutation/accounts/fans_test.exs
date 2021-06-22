defmodule GroupherServer.Test.Mutation.Accounts.Fans do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.Accounts
  alias Accounts.Model.User

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user, user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[Accounts follower]" do
    @query """
    mutation($login: String!) {
      follow(login: $login) {
        id
        viewerHasFollowed
      }
    }
    """
    test "login user can follow other user", ~m(user_conn)a do
      {:ok, user2} = db_insert(:user)

      variables = %{login: user2.login}
      followed = user_conn |> mutation_result(@query, variables, "follow")

      assert followed["id"] == to_string(user2.id)
      assert followed["viewerHasFollowed"] == false
    end

    test "login user follow other user twice fails", ~m(user_conn)a do
      {:ok, user2} = db_insert(:user)

      variables = %{login: user2.login}
      followed = user_conn |> mutation_result(@query, variables, "follow")
      assert followed["id"] == to_string(user2.id)

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:already_did))
    end

    test "login user follow self fails", ~m(user_conn user)a do
      variables = %{login: user.login}
      assert user_conn |> mutation_get_error?(@query, variables, ecode(:self_conflict))
    end

    test "login user follow no-exsit cuser fails", ~m(user_conn)a do
      variables = %{login: non_exsit_login()}

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:not_exsit))
    end

    test "unauth user follow other user fails", ~m(guest_conn)a do
      {:ok, user2} = db_insert(:user)
      variables = %{login: user2.login}
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($login: String!) {
      undoFollow(login: $login) {
        id
      }
    }
    """

    test "login user can undo follow other user", ~m(user_conn user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      {:ok, found} = User |> ORM.find(user2.id, preload: :followers)
      assert found |> Map.get(:followers) |> length == 1

      variables = %{login: user2.login}
      result = user_conn |> mutation_result(@query, variables, "undoFollow")

      assert result["id"] == to_string(user2.id)

      {:ok, found} = User |> ORM.find(user2.id, preload: :followers)
      assert found |> Map.get(:followers) |> length == 0

      {:ok, found} = User |> ORM.find(user2.id, preload: :followings)
      assert found |> Map.get(:followings) |> length == 0
    end
  end
end
