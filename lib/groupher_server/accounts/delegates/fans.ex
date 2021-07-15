defmodule GroupherServer.Accounts.Delegate.Fans do
  @moduledoc """
  user followers / following related
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, ensure: 2]
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.{ORM, QueryBuilder, Later, SpecType}
  alias GroupherServer.{Accounts, Repo}

  alias Accounts.Model.{User, Embeds, UserFollower, UserFollowing}
  alias Accounts.Delegate.Hooks

  alias Ecto.Multi

  @default_user_meta Embeds.UserMeta.default_meta()

  @doc """
  follow a user
  """
  @spec follow(User.t(), User.t()) :: {:ok, User.t()} | SpecType.gq_error()
  def follow(%User{} = user, %User{} = follower) do
    with true <- to_string(user.id) !== to_string(follower.id),
         {:ok, target_user} <- ORM.find(User, follower.id) do
      Multi.new()
      |> Multi.insert(
        :create_follower,
        UserFollower.changeset(%UserFollower{}, %{user_id: target_user.id, follower_id: user.id})
      )
      |> Multi.insert(
        :create_following,
        UserFollowing.changeset(%UserFollowing{}, %{
          user_id: user.id,
          following_id: target_user.id
        })
      )
      |> Multi.run(:update_user_follow_info, fn _, _ ->
        update_user_follow_info(target_user, user.id, :add)
      end)
      |> Multi.run(:add_achievement, fn _, _ ->
        Accounts.achieve(%User{id: target_user.id}, :inc, :follow)
      end)
      |> Multi.run(:after_hooks, fn _, _ ->
        Later.run({Hooks.Notify, :handle, [:follow, user, follower]})
      end)
      |> Repo.transaction()
      |> result()
    else
      false -> {:error, [message: "can't follow yourself", code: ecode(:self_conflict)]}
      {:error, reason} -> {:error, [message: reason, code: ecode(:not_exsit)]}
    end
  end

  @doc """
  undo a follow action to a user
  """
  @spec undo_follow(User.t(), User.t()) :: {:ok, User.t()} | SpecType.gq_error()
  def undo_follow(%User{} = user, %User{} = follower) do
    with true <- to_string(user.id) !== to_string(follower.id),
         {:ok, target_user} <- ORM.find(User, follower.id) do
      Multi.new()
      |> Multi.run(:delete_follower, fn _, _ ->
        ORM.findby_delete!(UserFollower, %{user_id: target_user.id, follower_id: user.id})
      end)
      |> Multi.run(:delete_following, fn _, _ ->
        ORM.findby_delete!(UserFollowing, %{user_id: user.id, following_id: target_user.id})
      end)
      |> Multi.run(:update_user_follow_info, fn _, _ ->
        update_user_follow_info(target_user, user.id, :remove)
      end)
      |> Multi.run(:minus_achievement, fn _, _ ->
        Accounts.achieve(%User{id: target_user.id}, :dec, :follow)
      end)
      |> Multi.run(:after_hooks, fn _, _ ->
        Later.run({Hooks.Notify, :handle, [:undo, :follow, user, follower]})
      end)
      |> Repo.transaction()
      |> result()
    else
      false -> {:error, [message: "can't undo follow yourself", code: ecode(:self_conflict)]}
      {:error, reason} -> {:error, [message: reason, code: ecode(:not_exsit)]}
    end
  end

  # update follow in user meta
  defp update_user_follow_info(%User{} = target_user, user_id, opt) do
    with {:ok, user} <- ORM.find(User, user_id) do
      target_user_meta = ensure(target_user.meta, @default_user_meta)
      user_meta = ensure(user.meta, @default_user_meta)

      follower_user_ids =
        case opt do
          :add -> (target_user_meta.follower_user_ids ++ [user_id]) |> Enum.uniq()
          :remove -> (target_user_meta.follower_user_ids -- [user_id]) |> Enum.uniq()
        end

      following_user_ids =
        case opt do
          :add -> (user_meta.following_user_ids ++ [target_user.id]) |> Enum.uniq()
          :remove -> (user_meta.following_user_ids -- [target_user.id]) |> Enum.uniq()
        end

      Multi.new()
      |> Multi.run(:update_follower_meta, fn _, _ ->
        followers_count = length(follower_user_ids)
        meta = Map.merge(target_user_meta, %{follower_user_ids: follower_user_ids})

        ORM.update_meta(target_user, meta, changes: %{followers_count: followers_count})
      end)
      |> Multi.run(:update_following_meta, fn _, _ ->
        followings_count = length(following_user_ids)
        meta = Map.merge(user_meta, %{following_user_ids: following_user_ids})

        ORM.update_meta(user, meta, changes: %{followings_count: followings_count})
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc """
  get paged followers of a user
  """
  def paged_followers(%User{id: user_id}, filter, %User{} = cur_user) do
    paged_followers(%User{id: user_id}, filter)
    |> mark_viewer_follow_status(cur_user)
    |> done
  end

  @spec paged_followers(User.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def paged_followers(%User{id: user_id}, filter) do
    UserFollower
    |> where([uf], uf.user_id == ^user_id)
    |> join(:inner, [uf], u in assoc(uf, :follower))
    |> load_fans(filter)
  end

  @doc """
  get paged followings of a user
  """
  def paged_followings(%User{id: user_id}, filter, %User{} = cur_user) do
    paged_followings(%User{id: user_id}, filter)
    |> mark_viewer_follow_status(cur_user)
    |> done
  end

  @spec paged_followings(User.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def paged_followings(%User{id: user_id}, filter) do
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
    |> ORM.paginator(~m(page size)a)
    |> done()
  end

  @doc """
  mark viewer's follower/followings states
  """
  def mark_viewer_follow_status({:ok, %{entries: entries} = paged_users}, cur_user) do
    entries = Enum.map(entries, &Map.merge(&1, do_mark_viewer_has_states(&1.id, cur_user)))
    Map.merge(paged_users, %{entries: entries})
  end

  def mark_viewer_follow_status({:error, reason}), do: {:error, reason}

  defp do_mark_viewer_has_states(user_id, %User{meta: nil}) do
    %{viewer_been_followed: false, viewer_has_followed: false}
  end

  defp do_mark_viewer_has_states(user_id, %User{meta: meta}) do
    %{
      viewer_been_followed: Enum.member?(meta.follower_user_ids, user_id),
      viewer_has_followed: Enum.member?(meta.following_user_ids, user_id)
    }
  end

  @spec result({:ok, map()}) :: SpecType.done()
  defp result({:ok, %{create_follower: user_follower}}) do
    User |> ORM.find(user_follower.user_id)
  end

  defp result({:ok, %{delete_follower: user_follower}}) do
    User |> ORM.find(user_follower.user_id)
  end

  defp result({:ok, %{update_follower_meta: result}}) do
    {:ok, result}
  end

  defp result({:error, :create_follower, %Ecto.Changeset{}, _steps}) do
    {:error, [message: "already followed", code: ecode(:already_did)]}
  end

  defp result({:error, :create_follower, _result, _steps}) do
    {:error, [message: "already followed", code: ecode(:already_did)]}
  end

  defp result({:error, :create_following, _result, _steps}) do
    {:error, [message: "follow fails", code: ecode(:react_fails)]}
  end

  defp result({:error, :delete_follower, _result, _steps}) do
    {:error, [message: "already unfollowed", code: ecode(:already_did)]}
  end

  defp result({:error, :delete_following, _result, _steps}) do
    {:error, [message: "unfollow fails", code: ecode(:react_fails)]}
  end

  defp result({:error, :minus_achievement, _result, _steps}) do
    {:error, [message: "follow acieve fails", code: ecode(:react_fails)]}
  end

  defp result({:error, :add_achievement, _result, _steps}) do
    {:error, [message: "follow acieve fails", code: ecode(:react_fails)]}
  end
end
