defmodule GroupherServer.Accounts.Helper.Loader do
  @moduledoc """
  dataloader for accounts
  """
  import Ecto.Query, warn: false

  alias Helper.QueryBuilder
  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.{CommunitySubscriber}

  def data, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query({"communities_subscribers", CommunitySubscriber}, %{filter: filter}) do
    CommunitySubscriber
    |> QueryBuilder.filter_pack(filter)
    |> join(:inner, [u], c in assoc(u, :community))
    |> select([u, c], c)
  end

  def query(queryable, _args), do: queryable
end
