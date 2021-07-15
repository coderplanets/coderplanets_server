defmodule GroupherServer.Accounts.Delegate.Achievements do
  @moduledoc """
  user achievements related
  acheiveements formula:
  1. create content been upvoteed by other user + 1
  2. create content been watched by other user + 1
  3. create content been colleced by other user + 2
  4. followed by other user + 3
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2, done: 1]
  import ShortMaps

  alias Helper.{ORM, SpecType}
  alias GroupherServer.Accounts.Model.{Achievement, User}

  alias GroupherServer.CMS.Model.CommunityEditor

  @collect_weight get_config(:general, :user_achieve_collect_weight)
  @upvote_weight get_config(:general, :user_achieve_upvote_weight)
  # @watch_weight get_config(:general, :user_achieve_watch_weight)
  @follow_weight get_config(:general, :user_achieve_follow_weight)

  @doc """
  inc user's achievement by inc followers_count of collect_weight
  """
  @spec achieve(User.t(), atom, atom) :: SpecType.done()
  def achieve(%User{id: user_id}, :inc, :follow) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      followers_count = achievement.followers_count + 1
      reputation = achievement.reputation + @follow_weight

      achievement
      |> ORM.update(~m(followers_count reputation)a)
    end
  end

  @doc """
  dec user's achievement by inc followers_count of collect_weight
  """
  def achieve(%User{id: user_id}, :dec, :follow) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      followers_count = max(achievement.followers_count - 1, 0)
      reputation = max(achievement.reputation - @follow_weight, 0)

      achievement
      |> ORM.update(~m(followers_count reputation)a)
    end
  end

  @doc """
  inc user's achievement by articles_upvotes_count of upvote_weight
  """
  def achieve(%User{id: user_id} = _user, :inc, :upvote) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      articles_upvotes_count = achievement.articles_upvotes_count + 1
      reputation = achievement.reputation + @upvote_weight

      achievement
      |> ORM.update(~m(articles_upvotes_count reputation)a)
    end
  end

  @doc """
  dec user's achievement by articles_upvotes_count of upvote_weight
  """
  def achieve(%User{id: user_id} = _user, :dec, :upvote) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      articles_upvotes_count = max(achievement.articles_upvotes_count - 1, 0)
      reputation = max(achievement.reputation - @upvote_weight, 0)

      achievement
      |> ORM.update(~m(articles_upvotes_count reputation)a)
    end
  end

  @doc """
  dec user's achievement by articles_collects_count of collect_weight
  """
  def achieve(%User{id: user_id} = _user, :inc, :collect) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      articles_collects_count = achievement.articles_collects_count + 1
      reputation = achievement.reputation + @collect_weight

      achievement
      |> ORM.update(~m(articles_collects_count reputation)a)
    end
  end

  @doc """
  inc user's achievement by articles_collects_count of collect_weight
  """
  def achieve(%User{id: user_id} = _user, :dec, :collect) do
    with {:ok, achievement} <- ORM.findby_or_insert(Achievement, ~m(user_id)a, ~m(user_id)a) do
      articles_collects_count = max(achievement.articles_collects_count - 1, 0)

      reputation = max(achievement.reputation - @collect_weight, 0)

      achievement
      |> ORM.update(~m(articles_collects_count reputation)a)
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
  def downgrade_achievement(%User{id: user_id}, :collect, count) do
    with {:ok, achievement} <- ORM.find_by(Achievement, user_id: user_id) do
      articles_collects_count = max(achievement.articles_collects_count - count, 0)
      reputation = max(achievement.reputation - count * @collect_weight, 0)

      achievement |> ORM.update(~m(articles_collects_count reputation)a)
    end
  end

  @doc """
  list communities which the user is editor in it
  """

  def paged_editable_communities(%User{id: user_id}, %{page: page, size: size}) do
    with {:ok, user} <- ORM.find(User, user_id) do
      CommunityEditor
      |> where([e], e.user_id == ^user.id)
      |> join(:inner, [e], c in assoc(e, :community))
      |> select([e, c], c)
      |> ORM.paginator(page: page, size: size)
      |> done()
    end
  end
end
