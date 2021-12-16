defmodule GroupherServer.CMS.Delegate.Search do
  @moduledoc """
  search for community, post, job ...
  """

  import Helper.Utils, only: [done: 1, ensure: 2]
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher

  alias Helper.ORM

  alias GroupherServer.{Accounts, CMS}
  alias CMS.Model.{Community}
  alias Accounts.Model.{User}

  @default_user_meta Accounts.Model.Embeds.UserMeta.default_meta()

  @search_items_count 15

  @doc """
  search community by title
  """
  def search_communities(title) do
    do_search_communities(Community, title)
  end

  def search_communities(title, %User{meta: meta}) do
    with {:ok, communities} <- do_search_communities(Community, title) do
      user_meta = ensure(meta, @default_user_meta)
      %{entries: entries} = communities

      entries =
        Enum.map(entries, fn community ->
          viewer_has_subscribed = community.id in user_meta.subscribed_communities_ids
          %{community | viewer_has_subscribed: viewer_has_subscribed}
        end)

      %{communities | entries: entries} |> done
    end
  end

  def search_communities(title, category, %User{meta: meta}) do
    search_communities(title, category)
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
    |> where(
      [c],
      ilike(c.title, ^"%#{title}%") or ilike(c.raw, ^"%#{title}%") or ilike(c.aka, ^"%#{title}%")
    )
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
