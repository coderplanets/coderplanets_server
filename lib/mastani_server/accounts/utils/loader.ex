defmodule MastaniServer.Accounts.Utils.Loader do
  @moduledoc """
  dataloader for accounts
  """
  import Ecto.Query, warn: false

  alias Helper.QueryBuilder
  alias MastaniServer.{Accounts, CMS, Repo}

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

  # stared contents count
  def query({"posts_stars", CMS.PostStar}, %{count: _}) do
    CMS.PostStar |> count_contents
  end

  def query({"jobs_stars", CMS.JobStar}, %{count: _}) do
    CMS.JobStar |> count_contents
  end

  def query({"videos_stars", CMS.VideoStar}, %{count: _}) do
    CMS.VideoStar |> count_contents
  end

  # favorited contents count
  def query({"posts_favorites", CMS.PostFavorite}, %{count: _}) do
    CMS.PostFavorite |> count_contents
  end

  def query({"jobs_favorites", CMS.JobFavorite}, %{count: _}) do
    CMS.JobFavorite |> count_contents
  end

  def query({"videos_favorites", CMS.VideoFavorite}, %{count: _}) do
    CMS.VideoFavorite |> count_contents
  end

  def query({"repos_favorites", CMS.RepoFavorite}, %{count: _}) do
    CMS.RepoFavorite |> count_contents
  end

  def query(queryable, _args), do: queryable

  defp count_contents(queryable) do
    queryable
    |> group_by([f], f.user_id)
    |> select([f], count(f.id))
  end
end
