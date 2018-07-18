defmodule MastaniServer.Accounts.Delegate.Fans do
  @moduledoc """
  user followers / following related
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.{ORM, QueryBuilder, SpecType}
  alias MastaniServer.{Accounts, Repo}

  alias MastaniServer.Accounts.{User, UserFollower, UserFollowing}

  alias Ecto.Multi

  @doc """
  follow a user
  """
  @spec follow(User.t(), User.t()) :: {:ok, User.t()} | SpecType.gq_error()
  def follow(%User{id: user_id}, %User{id: follower_id}) do
    with true <- to_string(user_id) !== to_string(follower_id),
         {:ok, _follow_user} <- ORM.find(User, follower_id) do
      Multi.new()
      |> Multi.insert(
        :create_follower,
        UserFollower.changeset(%UserFollower{}, ~m(user_id follower_id)a)
      )
      |> Multi.insert(
        :create_following,
        UserFollowing.changeset(%UserFollowing{}, %{user_id: user_id, following_id: follower_id})
      )
      |> Multi.run(:add_achievement, fn _ ->
        Accounts.achieve(%User{id: follower_id}, :add, :follow)
      end)
      |> Repo.transaction()
      |> follow_result()
    else
      false ->
        {:error, [message: "can't follow yourself", code: ecode(:self_conflict)]}

      {:error, error} ->
        {:error, [message: error, code: ecode(:not_exsit)]}
    end
  end

  @spec follow_result({:ok, map()}) :: SpecType.done()
  defp follow_result({:ok, %{create_follower: user_follower}}) do
    User |> ORM.find(user_follower.follower_id)
  end

  defp follow_result({:error, :create_follower, _result, _steps}) do
    {:error, [message: "already followed", code: ecode(:already_did)]}
  end

  defp follow_result({:error, :create_following, _result, _steps}) do
    {:error, [message: "follow fails", code: ecode(:react_fails)]}
  end

  defp follow_result({:error, :add_achievement, _result, _steps}) do
    {:error, [message: "follow acieve fails", code: ecode(:react_fails)]}
  end

  @doc """
  undo a follow action to a user
  """
  @spec undo_follow(User.t(), User.t()) :: {:ok, User.t()} | SpecType.gq_error()
  def undo_follow(%User{id: user_id}, %User{id: follower_id}) do
    with true <- to_string(user_id) !== to_string(follower_id),
         {:ok, _follow_user} <- ORM.find(User, follower_id) do
      Multi.new()
      |> Multi.run(:delete_follower, fn _ ->
        ORM.findby_delete(UserFollower, ~m(user_id follower_id)a)
      end)
      |> Multi.run(:delete_following, fn _ ->
        ORM.findby_delete(UserFollowing, %{user_id: user_id, following_id: follower_id})
      end)
      |> Multi.run(:minus_achievement, fn _ ->
        Accounts.achieve(%User{id: follower_id}, :minus, :follow)
      end)
      |> Repo.transaction()
      |> undo_follow_result()
    else
      false ->
        {:error, [message: "can't undo follow yourself", code: ecode(:self_conflict)]}

      {:error, error} ->
        {:error, [message: error, code: ecode(:not_exsit)]}
    end
  end

  defp undo_follow_result({:ok, %{delete_follower: user_follower}}) do
    User |> ORM.find(user_follower.follower_id)
  end

  defp undo_follow_result({:error, :delete_follower, _result, _steps}) do
    {:error, [message: "already unfollowed", code: ecode(:already_did)]}
  end

  defp undo_follow_result({:error, :delete_following, _result, _steps}) do
    {:error, [message: "unfollow fails", code: ecode(:react_fails)]}
  end

  defp undo_follow_result({:error, :minus_achievement, _result, _steps}) do
    {:error, [message: "follow acieve fails", code: ecode(:react_fails)]}
  end

  @doc """
  get paged followers of a user
  """
  @spec fetch_followers(User.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def fetch_followers(%User{id: user_id}, filter) do
    UserFollower
    |> where([uf], uf.follower_id == ^user_id)
    |> join(:inner, [uf], u in assoc(uf, :user))
    |> load_fans(filter)
  end

  @doc """
  get paged followings of a user
  """
  @spec fetch_followings(User.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def fetch_followings(%User{id: user_id}, filter) do
    UserFollowing
    |> where([uf], uf.user_id == ^user_id)
    |> join(:inner, [uf], u in assoc(uf, :following))
    |> load_fans(filter)
  end

  @spec load_fans(Ecto.Queryable.t(), map()) :: {:ok, map()} | {:error, String.t()}
  defp load_fans(queryable, ~m(page size)a = filter) do
    queryable
    |> select([uf, u], u)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end
end
