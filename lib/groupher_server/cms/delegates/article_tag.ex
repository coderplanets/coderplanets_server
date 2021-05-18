defmodule GroupherServer.CMS.Delegate.ArticleTag do
  @moduledoc """
  community curd
  """
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher
  import Helper.Utils, only: [done: 1, map_atom_value: 2]
  import GroupherServer.CMS.Delegate.ArticleCURD, only: [ensure_author_exists: 1]
  import ShortMaps

  alias Helper.ORM
  alias Helper.QueryBuilder
  alias GroupherServer.{Accounts, Repo}

  alias GroupherServer.CMS.{Community, ArticleTag}

  @doc """
  create a article tag
  """
  def create_article_tag(%Community{id: community_id}, thread, attrs, %Accounts.User{id: user_id}) do
    with {:ok, author} <- ensure_author_exists(%Accounts.User{id: user_id}),
         {:ok, community} <- ORM.find(Community, community_id) do
      thread = thread |> to_string |> String.upcase()

      attrs =
        attrs |> Map.merge(%{author_id: author.id, community_id: community.id, thread: thread})

      ArticleTag |> ORM.create(attrs)
    end
  end

  def update_article_tag(id, attrs) do
    with {:ok, article_tag} <- ORM.find(ArticleTag, id) do
      ORM.update(article_tag, attrs)
    end
  end

  @doc """
  get all tags belongs to a community
  """
  def get_tags(%Community{id: community_id}) when not is_nil(community_id) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c, cp], c.id == ^community_id)
    |> Repo.all()
    |> done()
  end

  def get_tags(%Community{raw: community_raw}) when not is_nil(community_raw) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c, cp], c.raw == ^community_raw)
    |> Repo.all()
    |> done()
  end

  @doc """
  get all paged tags
  """
  def get_tags(%{page: page, size: size} = filter) do
    Tag
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  @doc """
  get tags belongs to a community / thread
  """
  def get_tags(%Community{raw: community_raw}, thread) when not is_nil(community_raw) do
    thread = thread |> to_string |> String.downcase()

    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.raw == ^community_raw and t.thread == ^thread)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  def get_tags(%Community{id: community_id}, thread) when not is_nil(community_id) do
    # thread = thread |> to_string |> String.upcase()
    thread = thread |> to_string |> String.downcase()

    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.id == ^community_id and t.thread == ^thread)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  def get_tags(%Community{raw: community_raw}, thread) do
    thread = thread |> to_string |> String.downcase()

    result = get_tags_query(community_raw, thread)

    case result do
      {:ok, []} ->
        with {:ok, community} <- ORM.find_by(Community, aka: community_raw) do
          get_tags_query(community.raw, thread)
        else
          _ -> {:ok, []}
        end

      {:ok, ret} ->
        {:ok, ret}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_tags_query(community_raw, thread) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.raw == ^community_raw and t.thread == ^thread)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end
end
