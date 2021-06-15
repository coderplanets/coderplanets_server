defmodule GroupherServer.CMS.Delegate.CitedContent do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false

  import Helper.Utils, only: [done: 1, get_config: 2]
  import ShortMaps

  alias Helper.Types, as: T
  alias GroupherServer.{CMS, Repo}
  alias Helper.ORM

  alias CMS.Model.CitedContent

  @article_threads get_config(:article, :threads)

  @article_preloads @article_threads |> Enum.map(&Keyword.new([{&1, [author: :user]}]))

  @comment_article_preloads @article_threads |> Enum.map(&Keyword.new([{:comment, &1}]))
  @cited_preloads @article_preloads ++ [[comment: :author] ++ @comment_article_preloads]

  @doc "get paged citing contents"
  def paged_citing_contents(cited_by_id, %{page: page, size: size}) do
    CitedContent
    |> where([c], c.cited_by_id == ^cited_by_id)
    |> ORM.paginater(~m(page size)a)
    |> extract_contents
    |> done
  end

  def extract_contents(%{entries: entries} = paged_contents) do
    entries = entries |> Repo.preload(@cited_preloads) |> Enum.map(&shape_article(&1))

    Map.put(paged_contents, :entries, entries)
  end

  defp thread_to_atom(thread), do: thread |> String.downcase() |> String.to_atom()

  # shape comment cite
  @spec shape_article(CitedContent.t()) :: T.cite_info()
  defp shape_article(%CitedContent{comment_id: comment_id} = cited) when not is_nil(comment_id) do
    %{block_linker: block_linker, cited_by_type: cited_by_type, comment: comment} = cited

    comment_thread = comment.thread |> String.downcase() |> String.to_atom()
    article = comment |> Map.get(comment_thread)
    user = comment.author |> Map.take([:login, :nickname, :avatar])

    article
    |> Map.take([:id, :title])
    |> Map.merge(%{
      updated_at: comment.updated_at,
      user: user,
      thread: thread_to_atom(cited_by_type),
      comment_id: comment.id,
      block_linker: block_linker
    })
  end

  # shape general article cite
  defp shape_article(%CitedContent{} = cited) do
    %{block_linker: block_linker, cited_by_type: cited_by_type} = cited

    thread = thread_to_atom(cited_by_type)
    article = Map.get(cited, thread)

    user = get_in(article, [:author, :user]) |> Map.take([:login, :nickname, :avatar])

    article
    |> Map.take([:id, :title, :updated_at])
    |> Map.merge(%{user: user, thread: thread, block_linker: block_linker})
  end
end
