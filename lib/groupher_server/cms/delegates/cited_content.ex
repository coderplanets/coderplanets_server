defmodule GroupherServer.CMS.Delegate.CitedContent do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false

  import GroupherServer.CMS.Helper.Matcher
  import Helper.Utils, only: [done: 1, get_config: 2]
  import ShortMaps

  alias GroupherServer.{CMS, Repo}
  alias Helper.ORM

  alias CMS.Model.CitedContent

  @article_threads get_config(:article, :threads)
  @cited_preloads @article_threads |> Enum.map(&Keyword.new([{&1, [author: :user]}]))

  """
  article:
  thread title timestamp who

  comment:
  thread title/的评论(digest)中 timestamp who

  %Article {
    thread: "",
    id: "",
    title: "",
    updatedAt: "",
    user: %User{},
    block_linker: [],

    in_comment: boolean

    user: %User{},
  }
  """

  @doc "get paged citing contents"
  def paged_citing_contents(cited_by_id, %{page: page, size: size} = filter) do
    CitedContent
    |> where([c], c.cited_by_id == ^cited_by_id)
    |> ORM.paginater(~m(page size)a)
    |> extract_contents
    |> IO.inspect(label: "bb")
  end

  def extract_contents(%{entries: entries} = paged_contents) do
    entries = entries |> Repo.preload(@cited_preloads) |> Enum.map(&shape_article(&1))

    Map.put(paged_contents, :entries, entries)
  end

  def shape_article(%CitedContent{} = cited) do
    thread = cited.cited_by_type |> String.downcase() |> String.to_atom()
    # original_community
    block_linker = cited.block_linker
    article = Map.get(cited, thread)

    thread = get_in(article, [:meta]) |> Map.get(:thread)
    user = get_in(article, [:author, :user]) |> Map.take([:login, :nickname, :avatar])

    article
    |> Map.take([:title, :updated_at])
    |> Map.merge(%{user: user, thread: thread, block_linker: block_linker})
  end
end
