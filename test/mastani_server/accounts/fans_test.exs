defmodule MastaniServer.Test.Accounts.FansTest do
  use MastaniServer.TestTools

  alias Helper.ORM
  alias MastaniServer.Accounts

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, ~m(user)a}
  end

  describe "[user fans]" do
    alias Accounts.User

    test "user can follow other user", ~m(user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      {:ok, found} = User |> ORM.find(user.id, preload: :followers)

      assert found |> Map.get(:followers) |> Enum.any?(&(&1.user_id == user.id))
      assert found |> Map.get(:followers) |> length == 1
    end

    test "user can get paged followers", ~m(user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      {:ok, followers} = Accounts.fetch_followers(user2, %{page: 1, size: 20})
      assert followers.entries |> Enum.any?(&(&1.id == user.id))
      assert followers |> is_valid_pagination?(:raw)
    end

    test "user can get paged followings", ~m(user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      {:ok, followings} = Accounts.fetch_followings(user, %{page: 1, size: 20})

      assert followings.entries |> Enum.any?(&(&1.id == user2.id))
      assert followings |> is_valid_pagination?(:raw)
    end

    test "user follow other user twice fails", ~m(user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)
      assert {:error, _} = user |> Accounts.follow(user2)
    end

    test "user can undo follow", ~m(user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      {:ok, found} = User |> ORM.find(user.id, preload: :followers)
      assert found |> Map.get(:followers) |> length == 1

      {:ok, _followeer} = user |> Accounts.undo_follow(user2)

      {:ok, found} = User |> ORM.find(user.id, preload: :followers)
      assert found |> Map.get(:followers) |> length == 0
    end
  end
end
