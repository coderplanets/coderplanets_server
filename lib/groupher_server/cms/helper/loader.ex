defmodule GroupherServer.CMS.Helper.Loader do
  @moduledoc """
  dataloader for cms context
  """
  import Ecto.Query, warn: false

  alias GroupherServer.{CMS, Repo}

  alias CMS.Model.{Author, CommunityThread}
  alias Helper.QueryBuilder

  def data, do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(Author, _args) do
    from(a in Author, join: u in assoc(a, :user), select: u)
  end

  def query({"communities_threads", CommunityThread}, _info) do
    from(
      ct in CommunityThread,
      join: t in assoc(ct, :thread),
      order_by: [asc: t.index],
      select: t
    )
  end

  # default loader
  def query(queryable, _args) do
    queryable
  end
end
