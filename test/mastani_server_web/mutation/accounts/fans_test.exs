defmodule MastaniServer.Test.Mutation.Accounts.Fans do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.Accounts

  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user, user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[Accounts follower]" do
    alias Accounts.User

    @query """
    mutation($userId: ID!) {
      follow(userId: $userId) {
        id
        viewerHasFollowed
      }
    }
    """
    test "login user can follow other user", ~m(user_conn)a do
      {:ok, user2} = db_insert(:user)

      variables = %{userId: user2.id}
      followed = user_conn |> mutation_result(@query, variables, "follow")

      assert followed["id"] == to_string(user2.id)
      assert followed["viewerHasFollowed"] == true
    end

    test "login user follow other user twice fails", ~m(user_conn)a do
      {:ok, user2} = db_insert(:user)

      variables = %{userId: user2.id}
      followed = user_conn |> mutation_result(@query, variables, "follow")
      assert followed["id"] == to_string(user2.id)

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:already_did))
    end

    test "login user follow self fails", ~m(user_conn user)a do
      variables = %{userId: user.id}
      assert user_conn |> mutation_get_error?(@query, variables, ecode(:self_conflict))
    end

    test "login user follow no-exsit cuser fails", ~m(user_conn)a do
      variables = %{userId: non_exsit_id()}

      assert user_conn |> mutation_get_error?(@query, variables, ecode(:not_exsit))
    end

    test "unauth user follow other user fails", ~m(guest_conn)a do
      {:ok, user2} = db_insert(:user)
      variables = %{userId: user2.id}
      assert guest_conn |> mutation_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    mutation($userId: ID!) {
      undoFollow(userId: $userId) {
        id
      }
    }
    """
    test "login user can undo follow other user", ~m(user_conn user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      {:ok, found} = User |> ORM.find(user2.id, preload: :followers)
      assert found |> Map.get(:followers) |> length == 1

      variables = %{userId: user2.id}
      user_conn |> mutation_result(@query, variables, "undoFollow")

      {:ok, found} = User |> ORM.find(user2.id, preload: :followers)
      assert found |> Map.get(:followers) |> length == 0

      {:ok, found} = User |> ORM.find(user2.id, preload: :followings)
      assert found |> Map.get(:followings) |> length == 0
    end
  end
end
