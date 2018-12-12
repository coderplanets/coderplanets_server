defmodule MastaniServer.Accounts.Delegate.Achievements do
  @moduledoc """
  user achievements related
  acheiveements formula:
  1. create content been stared by other user + 1
  2. create content been watched by other user + 1
  3. create content been favorited by other user + 2
  4. followed by other user + 3
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2, done: 1]
  import ShortMaps

  alias Helper.{ORM, SpecType}
  alias MastaniServer.Accounts.{Achievement, User}

  @favorite_weight get_config(:general, :user_achieve_favorite_weight)
  @star_weight get_config(:general, :user_achieve_star_weight)
  # @watch_weight get_config(:general, :user_achieve_watch_weight)
  @follow_weight get_config(:general, :user_achieve_follow_weight)

  @doc """
  add user's achievement by add followers_count of favorite_weight
  """
  @spec achieve(User.t(), atom, atom) :: SpecType.done()
  def achieve(%User{id: user_id}, :add, :follow) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      followers_count = achievement.followers_count + 1
      reputation = achievement.reputation + @follow_weight

      achievement
      |> ORM.update(~m(followers_count reputation)a)
    end
  end

  @doc """
  minus user's achievement by add followers_count of favorite_weight
  """
  def achieve(%User{id: user_id}, :minus, :follow) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      followers_count = max(achievement.followers_count - 1, 0)
      reputation = max(achievement.reputation - @follow_weight, 0)

      achievement
      |> ORM.update(~m(followers_count reputation)a)
    end
  end

  @doc """
  add user's achievement by contents_stared_count of star_weight
  """
  def achieve(%User{id: user_id} = _user, :add, :star) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      contents_stared_count = achievement.contents_stared_count + 1
      reputation = achievement.reputation + @star_weight

      achievement
      |> ORM.update(~m(contents_stared_count reputation)a)
    end
  end

  @doc """
  minus user's achievement by contents_stared_count of star_weight
  """
  def achieve(%User{id: user_id} = _user, :minus, :star) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      contents_stared_count = max(achievement.contents_stared_count - 1, 0)
      reputation = max(achievement.reputation - @star_weight, 0)

      achievement
      |> ORM.update(~m(contents_stared_count reputation)a)
    end
  end

  @doc """
  minus user's achievement by contents_favorited_count of favorite_weight
  """
  def achieve(%User{id: user_id} = _user, :add, :favorite) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      contents_favorited_count = achievement.contents_favorited_count + 1
      reputation = achievement.reputation + @favorite_weight

      achievement
      |> ORM.update(~m(contents_favorited_count reputation)a)
    end
  end

  @doc """
  add user's achievement by contents_favorited_count of favorite_weight
  """
  def achieve(%User{id: user_id} = _user, :minus, :favorite) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      contents_favorited_count = max(achievement.contents_favorited_count - 1, 0)

      reputation = max(achievement.reputation - @favorite_weight, 0)

      achievement
      |> ORM.update(~m(contents_favorited_count reputation)a)
    end
  end

  def set_member(%User{} = user, :donate), do: do_set_member(user, %{donate_member: true})
  def set_member(%User{} = user, :senior), do: do_set_member(user, %{senior_member: true})
  def set_member(%User{} = user, :sponsor), do: do_set_member(user, %{sponsor_member: true})
  def set_member(_user, _plan), do: {:error, "no such plan"}

  def do_set_member(%User{id: user_id}, attrs) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      achievement |> ORM.update(attrs)
    end
  end

  @doc """
  only used for user delete the farorited category, other case is auto
  """
  def downgrade_achievement(%User{id: user_id}, :favorite, count) do
    with {:ok, achievement} <- ORM.find_by(Achievement, user_id: user_id) do
      contents_favorited_count = max(achievement.contents_favorited_count - count, 0)
      reputation = max(achievement.reputation - count * @favorite_weight, 0)

      achievement
      |> ORM.update(~m(contents_favorited_count reputation)a)
    end
  end

  # @spec safe_minus(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  # defp safe_minus(count, unit) when is_integer(count) and is_integer(unit) and unit > 0 do
  # case count <= 0 do
  # true ->
  # 0

  # false ->
  # count - unit
  # end
  # end

  @doc """
  list communities which the user is editor in it
  """
  alias MastaniServer.CMS.CommunityEditor

  def list_editable_communities(%User{id: user_id}, %{page: page, size: size}) do
    with {:ok, user} <- ORM.find(User, user_id) do
      CommunityEditor
      |> where([e], e.user_id == ^user.id)
      |> join(:inner, [e], c in assoc(e, :community))
      |> select([e, c], c)
      |> ORM.paginater(page: page, size: size)
      |> done()
    end
  end
end
