defmodule GroupherServer.Accounts.Delegate.UpvotedArticles do
  @moduledoc """
  get contents(posts, jobs ...) that user upvotes
  """
  # import GroupherServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import ShortMaps

  alias Helper.{ORM, QueryBuilder}

  alias GroupherServer.CMS
  alias CMS.{ArticleUpvote}

  # TODO: move to Model
  @supported_uovoted_threads [:post, :job]

  @doc """
  get paged upvoted articles
  """
  def list_upvoted_articles(user_id, %{thread: thread} = filter) do
    thread_upcase = thread |> to_string |> String.upcase()
    where_query = dynamic([a], a.user_id == ^user_id and a.thread == ^thread_upcase)

    load_upvoted_articles(where_query, filter)
  end

  def list_upvoted_articles(user_id, filter) do
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
end
