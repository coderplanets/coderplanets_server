defmodule MastaniServer.Accounts.Delegate.Fans do
  @moduledoc """
  user followers / following related
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.{ORM, QueryBuilder}
  alias Helper.SpecType
  alias MastaniServer.Accounts.{User, UserFollower, UserFollowing}

  # TODO: use Multi
  @spec follow(User.t(), User.t()) :: User.t() | SpecType.gq_error()
  def follow(%User{id: user_id}, %User{id: follower_id}) do
    with true <- to_string(user_id) !== to_string(follower_id),
         {:ok, _follow_user} <- ORM.find(User, follower_id),
         {:ok, _} <- ORM.create(UserFollower, ~m(user_id follower_id)a),
         {:ok, _} <- ORM.create(UserFollowing, %{user_id: user_id, following_id: follower_id}) do
      User |> ORM.find(follower_id)
    else
      false ->
        {:error, [message: "can't follow yourself", code: ecode(:self_conflict)]}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, [message: "already followed", code: ecode(:already_did)]}

      {:error, error} ->
        {:error, [message: error, code: ecode(:not_exsit)]}
    end
  end

  @spec undo_follow(User.t(), User.t()) :: User.t() | {:error, Keyword.t()}
  def undo_follow(%User{id: user_id}, %User{id: follower_id}) do
    with true <- to_string(user_id) !== to_string(follower_id),
         {:ok, _follow_user} <- ORM.find(User, follower_id),
         {:ok, _} <- ORM.findby_delete(UserFollower, ~m(user_id follower_id)a),
         {:ok, _} <-
           ORM.findby_delete(UserFollowing, %{user_id: user_id, following_id: follower_id}) do
      User |> ORM.find(follower_id)
    else
      false ->
        {:error, [message: "can't undo follow yourself", code: ecode(:self_conflict)]}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, [message: "already unfollowed", code: ecode(:already_did)]}

      {:error, error} ->
        {:error, [message: error, code: ecode(:not_exsit)]}
    end
  end

  @spec fetch_followers(User.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def fetch_followers(%User{id: user_id}, filter) do
    UserFollower
    |> where([uf], uf.follower_id == ^user_id)
    |> join(:inner, [uf], u in assoc(uf, :user))
    |> load_fans(filter)
  end

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
