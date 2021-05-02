defmodule GroupherServer.Accounts.Delegate.ReactedArticles do
  @moduledoc """
  get contents(posts, jobs ...) that user reacted (star, favorite ..)
  """
  import GroupherServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import ShortMaps

  alias Helper.{ORM, QueryBuilder}

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.User
  alias CMS.{ArticleUpvote, ArticleCollect}

  @supported_uovoted_threads [:post, :job]

  def upvoted_articles(thread, filter, %User{id: user_id}) do
    thread_upcase = thread |> to_string |> String.upcase()
    where_query = dynamic([a], a.user_id == ^user_id and a.thread == ^thread_upcase)

    load_upvoted_articles(where_query, filter)
  end

  def upvoted_articles(filter, %User{id: user_id}) do
    where_query = dynamic([a], a.user_id == ^user_id)

    load_upvoted_articles(where_query, filter)
  end

  defp load_upvoted_articles(where_query, %{page: page, size: size} = filter) do
    query = from(a in ArticleUpvote, preload: ^@supported_uovoted_threads)

    query
    |> where(^where_query)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(~m(page size)a)
    |> ORM.extract_articles(@supported_uovoted_threads)
    |> done()
  end

  @doc """
  paged favorite contents of a spec category
  """
  def reacted_contents(thread, :favorite, category_id, ~m(page size)a = filter, %User{id: user_id}) do
    with {:ok, action} <- match_action(thread, :favorite) do
      action.reactor
      |> where([f], f.user_id == ^user_id)
      |> join(:inner, [f], p in assoc(f, ^thread))
      |> join(:inner, [f], c in assoc(f, :category))
      |> where([f, p, c], c.id == ^category_id)
      |> select([f, p], p)
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  @doc """
  paged favorited/stared contents
  """
  def reacted_contents(thread, react, ~m(page size)a = filter, %User{id: user_id}) do
    with {:ok, action} <- match_action(thread, react) do
      action.reactor
      |> where([f], f.user_id == ^user_id)
      |> join(:inner, [f], p in assoc(f, ^thread))
      |> select([f, p], p)
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end
end
