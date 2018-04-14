defmodule MastaniServer.Accounts.Loader do
  import Ecto.Query, warn: false

  alias MastaniServer.Repo
  alias MastaniServer.CMS

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

  def query(queryable, _args) do
    IO.inspect(queryable, label: 'account default query')
    queryable
  end
end
