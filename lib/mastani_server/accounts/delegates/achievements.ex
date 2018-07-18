defmodule MastaniServer.Accounts.Delegate.Achievements do
  @moduledoc """
  user achievements related
  acheiveements formula:
  1. create content been stared by other user + 1
  2. create content been watched by other user + 1
  3. create content been favorited by other user + 2
  4. followed by other user + 3
  """
  import Helper.Utils, only: [get_config: 2]
  import ShortMaps

  alias Helper.{ORM, SpecType}
  alias MastaniServer.Accounts.{Achievement, User}
  alias MastaniServer.Repo

  @favorite_weight get_config(:general, :user_achieve_favorite_weight)
  @star_weight get_config(:general, :user_achieve_star_weight)
  @watch_weight get_config(:general, :user_achieve_watch_weight)
  @follow_weight get_config(:general, :user_achieve_follow_weight)

  def fetch_achievements(_filter) do
  end

  @doc """
  add user's achievement by add followers_count of favorite_weight
  """
  @spec achieve(User.t(), atom, atom) :: SpecType.done()
  def achieve(%User{id: user_id}, :add, :follow) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      followers_count = achievement.followers_count + @follow_weight
      reputation = achievement.reputation + @follow_weight

      achievement
      |> ORM.update(~m(followers_count reputation)a)
    end
  end

  @doc """
  minus user's achievement by add followers_count of favorite_weight
  """
  @spec achieve(User.t(), atom, atom) :: SpecType.done()
  def achieve(%User{id: user_id}, :minus, :follow) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      followers_count = achievement.followers_count |> safe_minus(@follow_weight)
      reputation = achievement.reputation |> safe_minus(@follow_weight)

      achievement
      |> ORM.update(~m(followers_count reputation)a)
    end
  end

  @doc """
  add user's achievement by contents_stared_count of star_weight
  """
  @spec achieve(User.t(), atom, atom) :: SpecType.done()
  def achieve(%User{id: user_id} = _user, :add, :star) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      contents_stared_count = achievement.contents_stared_count + @star_weight
      reputation = achievement.reputation + @star_weight

      achievement
      |> ORM.update(~m(contents_stared_count reputation)a)
    end
  end

  @doc """
  minus user's achievement by contents_stared_count of star_weight
  """
  @spec achieve(User.t(), atom, atom) :: SpecType.done()
  def achieve(%User{id: user_id} = _user, :minus, :star) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      contents_stared_count = achievement.contents_stared_count |> safe_minus(@star_weight)
      reputation = achievement.reputation |> safe_minus(@star_weight)

      achievement
      |> ORM.update(~m(contents_stared_count reputation)a)
    end
  end

  @doc """
  minus user's achievement by contents_favorited_count of favorite_weight
  """
  @spec achieve(User.t(), atom, atom) :: SpecType.done()
  def achieve(%User{id: user_id} = _user, :add, :favorite) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      contents_favorited_count = achievement.contents_favorited_count + @favorite_weight
      reputation = achievement.reputation + @favorite_weight

      achievement
      |> ORM.update(~m(contents_favorited_count reputation)a)
    end
  end

  @doc """
  add user's achievement by contents_favorited_count of favorite_weight
  """
  @spec achieve(User.t(), atom, atom) :: SpecType.done()
  def achieve(%User{id: user_id} = _user, :minus, :favorite) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      contents_favorited_count =
        achievement.contents_favorited_count |> safe_minus(@favorite_weight)

      reputation = achievement.reputation |> safe_minus(@favorite_weight)

      achievement
      |> ORM.update(~m(contents_favorited_count reputation)a)
    end
  end

  def achieve(%User{} = _user, :+, :watch) do
    IO.inspect("acheiveements add :conent_watched")
  end

  def achieve(%User{} = _user, :+, key) do
    IO.inspect("acheiveements add #{key}")
  end

  def achieve(%User{} = _user, :-, _key) do
    IO.inspect("acheiveements plus")
  end

  @spec safe_minus(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp safe_minus(count, unit \\ 1) when is_integer(count) and is_integer(unit) and unit > 0 do
    case count <= 0 do
      true ->
        0

      false ->
        count - unit
    end
  end
end
