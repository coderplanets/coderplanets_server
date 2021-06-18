defmodule GroupherServer.CMS.Delegate.CitedArtiment do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false

  import Helper.Utils, only: [done: 1, get_config: 2, thread_of_article: 1]
  import GroupherServer.CMS.Helper.Matcher
  import ShortMaps

  alias Helper.Types, as: T
  alias GroupherServer.{CMS, Repo}

  alias Helper.{ORM, QueryBuilder}

  alias CMS.Model.{CitedArtiment, Comment}

  @article_threads get_config(:article, :threads)

  @article_preloads @article_threads |> Enum.map(&Keyword.new([{&1, [author: :user]}]))

  @comment_article_preloads @article_threads |> Enum.map(&Keyword.new([{:comment, &1}]))
  @cited_preloads @article_preloads ++ [[comment: :author] ++ @comment_article_preloads]

  @doc "get paged citing contents"
  def paged_citing_contents(cited_by_type, cited_by_id, %{page: page, size: size} = filter) do
    cited_by_type = cited_by_type |> to_string |> String.upcase()

    CitedArtiment
    |> where([c], c.cited_by_id == ^cited_by_id and c.cited_by_type == ^cited_by_type)
    |> QueryBuilder.filter_pack(Map.merge(filter, %{sort: :asc_inserted}))
    |> ORM.paginater(~m(page size)a)
    |> extract_contents
    |> done
  end

  @doc "delete all records before insert_all, this will dynamiclly update"
  # those cited info when update article
  # 插入引用记录之前先全部清除，这样可以在更新文章的时候自动计算引用信息
  def batch_delete_by(%Comment{} = comment) do
    from(c in CitedArtiment, where: c.comment_id == ^comment.id)
    |> ORM.delete_all(:if_exist)
  end

  def batch_delete_by(article) do
    with {:ok, thread} <- thread_of_article(article),
         {:ok, info} <- match(thread) do
      thread = thread |> to_string |> String.upcase()

      from(c in CitedArtiment,
        where: field(c, ^info.foreign_key) == ^article.id and c.cited_by_type == ^thread
      )
      |> ORM.delete_all(:if_exist)
    end
  end

  @doc "batch insert CitedArtiment record and update citing count"
  def batch_insert([]), do: {:ok, :pass}

  def batch_insert(cited_artiments) do
    # 注意这里多了 artiment 和 citting_time
    # artiment 是为了下一步更新 citting_count 预先加载的，避免单独 preload 消耗性能
    # citing_time 是因为 insert_all 必须要自己更新时间
    # see: https://github.com/elixir-ecto/ecto/issues/1932#issuecomment-314083252
    clean_cited_artiments =
      cited_artiments
      |> Enum.map(&(&1 |> Map.merge(%{inserted_at: &1.citing_time, updated_at: &1.citing_time})))
      |> Enum.map(&Map.delete(&1, :artiment))
      |> Enum.map(&Map.delete(&1, :citing_time))

    case {0, nil} !== Repo.insert_all(CitedArtiment, clean_cited_artiments) do
      true -> update_artiment_citing_count(cited_artiments)
      false -> {:error, "insert cited artiment error"}
    end
  end

  # update article/comment 's citting_count in meta
  defp update_artiment_citing_count(cited_artiments) do
    Enum.all?(cited_artiments, fn cited ->
      count_query = from(c in CitedArtiment, where: c.cited_by_id == ^cited.cited_by_id)
      count = Repo.aggregate(count_query, :count)

      artiment = cited.artiment
      meta = Map.merge(artiment.meta, %{citing_count: count})

      case artiment |> ORM.update_meta(meta) do
        {:ok, _} -> true
        {:error, _} -> false
      end
    end)
    |> done
  end

  defp extract_contents(%{entries: entries} = paged_contents) do
    entries = entries |> Repo.preload(@cited_preloads) |> Enum.map(&shape(&1))

    Map.put(paged_contents, :entries, entries)
  end

  # shape comment cite
  @spec shape(CitedArtiment.t()) :: T.cite_info()
  defp shape(%CitedArtiment{comment_id: comment_id} = cited) when not is_nil(comment_id) do
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
  defp shape(%CitedArtiment{} = cited) do
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
