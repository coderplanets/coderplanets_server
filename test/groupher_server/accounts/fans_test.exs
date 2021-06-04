defmodule GroupherServer.Test.Accounts.Fans do
  use GroupherServer.TestTools

  alias Helper.ORM
  alias GroupherServer.Accounts
  alias Accounts.Model.User

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, ~m(user)a}
  end

  describe "[user fans]" do
    test "user can follow other user", ~m(user)a do
      {:ok, user2} = db_insert(:user)

      {:ok, _followeer} = user |> Accounts.follow(user2)
      {:ok, found} = User |> ORM.find(user2.id, preload: :followers)

      assert found |> Map.get(:followers) |> Enum.any?(&(&1.follower_id == user.id))
      assert found |> Map.get(:followers) |> length == 1
    end

    test "follow user should update follow meta info", ~m(user)a do
      {:ok, user2} = db_insert(:user)

      {:ok, _} = Accounts.follow(user, user2)

      {:ok, user} = ORM.find(User, user.id)
      {:ok, user2} = ORM.find(User, user2.id)

      assert user.followings_count == 1
      assert user2.followers_count == 1

      assert user2.id in user.meta.following_user_ids
      assert user.id in user2.meta.follower_user_ids
    end

    test "user can get paged followers", ~m(user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      {:ok, followers} = Accounts.paged_followers(user2, %{page: 1, size: 20})
      assert followers.entries |> Enum.any?(&(&1.id == user.id))
      assert followers |> is_valid_pagination?(:raw)
    end

    test "user can get paged followings", ~m(user)a do
      {:ok, user2} = db_insert(:user)
      {:ok, _followeer} = user |> Accounts.follow(user2)

      {:ok, followings} = Accounts.paged_followings(user, %{page: 1, size: 20})

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

      {:ok, found} = User |> ORM.find(user2.id, preload: :followers)
      assert found |> Map.get(:followers) |> length == 1

      {:ok, _followeer} = user |> Accounts.undo_follow(user2)

      {:ok, found} = User |> ORM.find(user2.id, preload: :followers)
      assert found |> Map.get(:followers) |> length == 0
    end

    test "undo follow user should update follow meta info", ~m(user)a do
      {:ok, user2} = db_insert(:user)

      {:ok, _} = Accounts.follow(user, user2)

      {:ok, user} = ORM.find(User, user.id)
      {:ok, user2} = ORM.find(User, user2.id)

      assert user2.id in user.meta.following_user_ids
      assert user.id in user2.meta.follower_user_ids

      {:ok, _} = Accounts.undo_follow(user, user2)

      {:ok, user} = ORM.find(User, user.id)
      {:ok, user2} = ORM.find(User, user2.id)

      assert user.followings_count == 0
      assert user2.followers_count == 0

      assert user2.id not in user.meta.following_user_ids
      assert user.id not in user2.meta.follower_user_ids
    end
  end
end
