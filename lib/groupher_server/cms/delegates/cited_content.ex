defmodule GroupherServer.CMS.Delegate.CitedContent do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false

  import Helper.Utils, only: [done: 1, get_config: 2]
  import ShortMaps

  alias Helper.Types, as: T
  alias GroupherServer.{CMS, Repo}
  alias Helper.{ORM, QueryBuilder}

  alias CMS.Model.CitedContent

  @article_threads get_config(:article, :threads)

  @article_preloads @article_threads |> Enum.map(&Keyword.new([{&1, [author: :user]}]))

  @comment_article_preloads @article_threads |> Enum.map(&Keyword.new([{:comment, &1}]))
  @cited_preloads @article_preloads ++ [[comment: :author] ++ @comment_article_preloads]

  @doc "get paged citing contents"
  def paged_citing_contents(cited_by_type, cited_by_id, %{page: page, size: size} = filter) do
    cited_by_type = cited_by_type |> to_string |> String.upcase()

    CitedContent
    |> where([c], c.cited_by_id == ^cited_by_id and c.cited_by_type == ^cited_by_type)
    |> QueryBuilder.filter_pack(Map.merge(filter, %{sort: :asc_inserted}))
    |> ORM.paginater(~m(page size)a)
    |> extract_contents
    |> done
  end

  def extract_contents(%{entries: entries} = paged_contents) do
    entries = entries |> Repo.preload(@cited_preloads) |> Enum.map(&shape(&1))

    Map.put(paged_contents, :entries, entries)
  end

  # shape comment cite
  @spec shape(CitedContent.t()) :: T.cite_info()
  defp shape(%CitedContent{comment_id: comment_id} = cited) when not is_nil(comment_id) do
    %{block_linker: block_linker, comment: comment, inserted_at: inserted_at} = cited

    comment_thread = comment.thread |> String.downcase() |> String.to_atom()
    article = comment |> Map.get(comment_thread)
    article_thread = thread_to_atom(article.meta.thread)
    user = comment.author |> Map.take([:login, :nickname, :avatar])

    article
    |> Map.take([:id, :title])
    |> Map.merge(%{
      inserted_at: inserted_at,
      user: user,
      thread: article_thread,
      comment_id: comment.id,
      block_linker: block_linker
    })
  end

  # shape general article cite
  defp shape(%CitedContent{} = cited) do
    %{block_linker: block_linker, inserted_at: inserted_at} = cited

    thread = citing_thread(cited)
    article = Map.get(cited, thread)

    user = get_in(article, [:author, :user]) |> Map.take([:login, :nickname, :avatar])

    article
    |> Map.take([:id, :title])
    |> Map.merge(%{
      user: user,
      thread: thread,
      block_linker: block_linker,
      inserted_at: inserted_at
    })
  end

  # find thread_id that not empty
  # only used for shape
  defp citing_thread(cited) do
    @article_threads |> Enum.find(fn thread -> not is_nil(Map.get(cited, :"#{thread}_id")) end)
  end

  defp thread_to_atom(thread), do: thread |> String.downcase() |> String.to_atom()
end
