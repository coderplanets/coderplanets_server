defmodule GroupherServer.Accounts.Delegate.UpvotedArticles do
  @moduledoc """
  get contents(posts, jobs ...) that user upvotes
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, get_config: 2]
  import ShortMaps

  alias Helper.{ORM, QueryBuilder}

  alias GroupherServer.CMS
  alias CMS.Model.{ArticleUpvote}

  @article_threads get_config(:article, :threads)

  @doc """
  get paged upvoted articles
  """
  def paged_upvoted_articles(user_id, %{thread: thread} = filter) do
    thread = thread |> to_string |> String.upcase()
    where_query = dynamic([a], a.user_id == ^user_id and a.thread == ^thread)

    load_upvoted_articles(where_query, filter)
  end

  def paged_upvoted_articles(user_id, filter) do
    where_query = dynamic([a], a.user_id == ^user_id)

    load_upvoted_articles(where_query, filter)
  end

  defp load_upvoted_articles(where_query, %{page: page, size: size} = filter) do
    article_preload =
      @article_threads
      |> Enum.reduce([], fn thread, acc ->
        acc ++ Keyword.new([{thread, [author: :user]}])
      end)

    query = from(a in ArticleUpvote, preload: ^article_preload)

    query
    |> where(^where_query)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginator(~m(page size)a)
    |> ORM.extract_articles()
    |> done()
  end
end
