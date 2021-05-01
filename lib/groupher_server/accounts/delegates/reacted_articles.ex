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
  alias CMS.{ArticleUpvote}

  @supported_uovoted_thread [:post, :job]

  def upvoted_articles(_thread, filter, %User{id: user_id}) do
    %{page: page, size: size} = filter

    ArticleUpvote
    |> where([a], a.user_id == ^user_id)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(~m(page size)a)
    # 根据 thread 筛选出对应的 [article]
    |> done()
  end

  def upvoted_articles(%{page: page, size: size} = filter, %User{id: user_id}) do
    query = from(a in ArticleUpvote, preload: [:post, :job])

    query
    |> where([a], a.user_id == ^user_id)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(~m(page size)a)
    |> extract_articles(@supported_uovoted_thread)
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

  defp extract_articles(%{entries: entries} = paged_articles, supported_threads) do
    paged_articles
    |> Map.put(:entries, Enum.map(entries, &extract_article_info(&1, supported_threads)))
  end

  defp extract_article_info(reaction, supported_threads) do
    thread = Enum.find(supported_threads, &(not is_nil(Map.get(reaction, &1))))
    article = Map.get(reaction, thread)

    export_article_info(thread, article)
  end

  defp export_article_info(thread, article) do
    %{
      thread: thread,
      id: article.id,
      title: article.title
    }
  end
end
