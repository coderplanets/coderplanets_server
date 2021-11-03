defmodule GroupherServer.CMS.Delegate.Search do
  @moduledoc """
  search for community, post, job ...
  """

  import Helper.Utils, only: [done: 1]
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher

  alias Helper.ORM
  alias GroupherServer.CMS.Model.{Community}

  @search_items_count 15

  @doc """
  search community by title
  """
  def search_communities(title) do
    do_search_communities(Community, title)
  end

  def search_communities(title, category) do
    from(
      c in Community,
      join: cat in assoc(c, :categories),
      where: cat.raw == ^category
    )
    |> do_search_communities(title)
  end

  defp do_search_communities(queryable, title) do
    queryable
    |> where([c], ilike(c.title, ^"%#{title}%") or ilike(c.raw, ^"%#{title}%"))
    |> ORM.paginator(page: 1, size: @search_items_count)
    |> done()
  end

  @doc """
  search article by title
  """
  def search_articles(thread, %{title: title}) do
    with {:ok, info} <- match(thread) do
      info.model
      # |> where([c], ilike(c.title, ^"%#{title}%") or ilike(c.digest, ^"%#{title}%"))
      |> where([c], ilike(c.title, ^"%#{title}%"))
      |> ORM.paginator(page: 1, size: @search_items_count)
      |> done()
    end
  end
end
