defmodule MastaniServer.Accounts.Utils.Loader do
  import Ecto.Query, warn: false

  alias MastaniServer.{Repo, CMS}
  alias Helper.QueryBuilder

  def data(), do: Dataloader.Ecto.new(Repo, query: &query/2)

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

  def query({"posts_favorites", CMS.PostFavorite}, %{count: _}) do
    CMS.PostFavorite |> count_cotents
  end

  def query({"jobs_favorites", CMS.JobFavorite}, %{count: _}) do
    CMS.JobFavorite |> count_cotents
  end

  defp count_cotents(queryable) do
    queryable
    |> group_by([f], f.user_id)
    |> select([f], count(f.id))
  end

  def query(queryable, _args), do: queryable
end
