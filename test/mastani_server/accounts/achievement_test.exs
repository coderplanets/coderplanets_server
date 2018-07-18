defmodule MastaniServer.Test.Accounts.AchievementTest do
  use MastaniServer.TestTools

  import Helper.Utils, only: [get_config: 2]
  alias Helper.ORM
  alias MastaniServer.Accounts
  alias MastaniServer.Accounts.User

  @follow_weight get_config(:general, :user_achieve_follow_weight)
  @favorite_weight get_config(:general, :user_achieve_favorite_weight)
  @star_weight get_config(:general, :user_achieve_star_weight)
  # @watch_weight get_config(:general, :user_achieve_watch_weight)

  setup do
    {:ok, user} = db_insert(:user)

    {:ok, ~m(user)a}
  end

  describe "[Accounts Achievement funtion]" do
    alias Accounts.Achievement

    test "Accounts.achieve should inc / minus achievement by parts", ~m(user)a do
      user |> Accounts.achieve(:add, :follow)
      user |> Accounts.achieve(:add, :star)
      user |> Accounts.achieve(:add, :favorite)
      {:ok, achievement} = Achievement |> ORM.find_by(user_id: user.id)

      assert achievement.followers_count == @follow_weight
      assert achievement.contents_stared_count == @star_weight
      assert achievement.contents_favorited_count == @favorite_weight

      reputation = @follow_weight + @star_weight + @favorite_weight
      assert achievement.reputation == reputation

      user |> Accounts.achieve(:minus, :follow)
      user |> Accounts.achieve(:minus, :star)
      user |> Accounts.achieve(:minus, :favorite)

      {:ok, achievement} = Achievement |> ORM.find_by(user_id: user.id)
      assert achievement.followers_count == 0
      assert achievement.followers_count == 0
      assert achievement.followers_count == 0
      assert achievement.reputation == 0
    end

    test "Accounts.achieve can not minus count < 0", ~m(user)a do
      user |> Accounts.achieve(:minus, :follow)
      user |> Accounts.achieve(:minus, :star)
      user |> Accounts.achieve(:minus, :favorite)

      {:ok, achievement} = Achievement |> ORM.find_by(user_id: user.id)
      assert achievement.followers_count == 0
      assert achievement.followers_count == 0
      assert achievement.followers_count == 0
      assert achievement.reputation == 0
    end
  end

  describe "[follow achievement]" do
    test "user get achievement inc after other user follows", ~m(user)a do
      total_count = 20
      {:ok, users} = db_insert_multi(:user, 20)

      Enum.each(users, fn cool_user ->
        {:ok, _} = cool_user |> Accounts.follow(user)
      end)

      {:ok, user} = User |> ORM.find(user.id, preload: :achievement)

      assert user.achievement.followers_count == @follow_weight * total_count
      assert user.achievement.reputation == @follow_weight * total_count
    end

    test "user get achievement down after other user undo follows", ~m(user)a do
      total_count = 20
      {:ok, users} = db_insert_multi(:user, 20)

      Enum.each(users, fn cool_user ->
        {:ok, _} = cool_user |> Accounts.follow(user)
      end)

      one_folloer = users |> List.first()
      one_folloer |> Accounts.undo_follow(user)

      {:ok, user} = User |> ORM.find(user.id, preload: :achievement)

      assert user.achievement.followers_count == @follow_weight * (total_count - 1)
      assert user.achievement.reputation == @follow_weight * (total_count - 1)
    end
  end
end
