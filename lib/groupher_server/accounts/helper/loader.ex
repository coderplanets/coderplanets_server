defmodule GroupherServer.Accounts.Helper.Loader do
  @moduledoc """
  dataloader for accounts
  """
  import Ecto.Query, warn: false

  alias Helper.QueryBuilder
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.{UserFollower, UserFollowing}

  def data, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query({"communities_subscribers", CMS.CommunitySubscriber}, %{count: _}) do
    CMS.CommunitySubscriber
    |> group_by([f], f.user_id)
    |> select([f], count(f.id))
  end

  def query({"communities_subscribers", CMS.CommunitySubscriber}, %{filter: filter}) do
    CMS.CommunitySubscriber
    |> QueryBuilder.filter_pack(filter)
    |> join(:inner, [u], c in assoc(u, :community))
    |> select([u, c], c)
  end

  # TODO: fix later, this is not working
  def query({"users_followers", UserFollower}, %{count: _}) do
    UserFollower
    |> group_by([f], f.user_id)
    |> select([f], count(f.follower_id))
  end

  def query({"users_followings", UserFollowing}, %{count: _}) do
    UserFollowing
    |> group_by([f], f.user_id)
    |> select([f], count(f.id))
  end

  def query({"users_followers", UserFollower}, %{viewer_did: _, cur_user: cur_user}) do
    UserFollower |> where([f], f.follower_id == ^cur_user.id)
  end

  def query(queryable, _args), do: queryable

  defp count_contents(queryable) do
    queryable
    |> group_by([f], f.user_id)
    |> select([f], count(f.id))
  end
end
