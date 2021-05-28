defmodule GroupherServer.CMS.Delegate.Search do
  @moduledoc """
  search for community, post, job ...
  """

  import Helper.Utils, only: [done: 1]
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher

  alias Helper.ORM
  alias GroupherServer.CMS.{Community}

  @search_items_count 15

  @doc """
  search community by title
  """
  def search_communities(title) do
    Community
    |> where([c], ilike(c.title, ^"%#{title}%") or ilike(c.raw, ^"%#{title}%"))
    |> ORM.paginater(page: 1, size: @search_items_count)
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
      |> ORM.paginater(page: 1, size: @search_items_count)
      |> done()
    end
  end
end
