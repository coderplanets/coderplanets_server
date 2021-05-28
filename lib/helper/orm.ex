defmodule Helper.ORM do
  @moduledoc """
  General CORD functions
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, done: 3, add: 1]
  import ShortMaps

  import Helper.ErrorHandler

  alias Helper.Types, as: T
  alias GroupherServer.Repo
  alias Helper.{QueryBuilder, SpecType}

  @doc """
  a wrap for paginate request
  """
  def paginater(queryable, page: page, size: size) do
    queryable |> Repo.paginate(page: page, page_size: size)
  end

  def paginater(queryable, ~m(page size)a) do
    queryable |> Repo.paginate(page: page, page_size: size)
  end

  # NOTE: should have limit length for list, otherwise it will cause mem issues
  @doc "simu paginator in normal list, used for embeds_many etc"
  def embeds_paginater(list, %{page: page, size: size} = _filter) when is_list(list) do
    chunked_list = Enum.chunk_every(list, size)

    entries = chunked_list |> Enum.at(page - 1)
    total_count = list |> length

    %{
      entries: entries,
      page_number: page,
      page_size: size,
      total_count: total_count,
      total_pages: chunked_list |> length
    }
  end

  @doc """
  wrap Repo.get with preload and result/errer format handle
  """
  def find(queryable, id, preload: preload) do
    queryable
    |> preload(^preload)
    |> Repo.get(id)
    |> done(queryable, id)
  end

  @doc """
  simular to Repo.get/3, with standard result/error handle
  """
  @spec find(Ecto.Queryable.t(), SpecType.id()) :: {:ok, any()} | {:error, String.t()}
  def find(queryable, id) do
    queryable
    |> Repo.get(id)
    |> done(queryable, id)
  end

  @doc """
  simular to Repo.get_by/3, with standard result/error handle
  """
  def find_by(queryable, clauses) do
    queryable
    |> Repo.get_by(clauses)
    |> case do
      nil ->
        {:error, not_found_formater(queryable, clauses)}

      result ->
        {:ok, result}
    end
  end

  @doc """
  return pageinated Data required by filter
  """
  # TODO: find article not mark_delete by default
  def find_all(queryable, %{page: page, size: size} = filter) do
    queryable
    |> QueryBuilder.filter_pack(filter)
    |> paginater(page: page, size: size)
    |> done()
  end

  @doc """
  return  Data required by filter
  """
  # TODO: find article not in mark_delete by default
  def find_all(queryable, filter) do
    queryable |> QueryBuilder.filter_pack(filter) |> Repo.all() |> done()
  end

  @doc """
  Require queryable has a views fields to count the views of the queryable Modal
  """
  def read(queryable, id, inc: :views) do
    with {:ok, result} <- find(queryable, id) do
      result |> inc_views_count(queryable) |> done()
    end
  end

  def read_by(queryable, clauses, inc: :views) do
    with {:ok, result} <- find_by(queryable, clauses) do
      result |> inc_views_count(queryable) |> done()
    end
  end

  defp inc_views_count(content, queryable) do
    {1, [result]} =
      Repo.update_all(
        from(p in queryable, where: p.id == ^content.id, select: p.views),
        inc: [views: 1]
      )

    put_in(content.views, result)
  end

  @doc "safe increase field(must be integer) by 1"
  def inc_field(queryable, content, field) do
    {1, [updated_count]} =
      Repo.update_all(
        from(c in queryable,
          where: c.id == ^content.id,
          select: field(c, ^field)
        ),
        inc: ["#{field}": 1]
      )

    put_in(content[field], updated_count) |> done
  end

  def dec_field(queryable, content, field) do
    {1, [updated_count]} =
      Repo.update_all(
        from(c in queryable,
          where: c.id == ^content.id,
          select: field(c, ^field)
        ),
        inc: ["#{field}": -1]
      )

    put_in(content[field], Enum.max([0, updated_count])) |> done
  end

  @doc """
  NOTICE: this should be use together with Authorize/OwnerCheck etc Middleware
  DO NOT use it directly
  """
  def delete(content), do: Repo.delete(content)

  def find_delete!(queryable, id) do
    with {:ok, content} <- find(queryable, id) do
      delete(content)
    end
  end

  def findby_delete!(queryable, clauses) do
    with {:ok, content} <- find_by(queryable, clauses) do
      delete(content)
    end
  end

  def findby_delete(queryable, clauses) do
    case find_by(queryable, clauses) do
      {:ok, content} -> delete(content)
      _ -> {:ok, :pass}
    end
  end

  def findby_or_insert(queryable, clauses, attrs) do
    case queryable |> find_by(clauses) do
      {:ok, content} ->
        {:ok, content}

      {:error, _} ->
        queryable |> create(attrs)
    end
  end

  @doc """
  NOTE: this should be use together with passport_loader etc Middleware
  DO NOT use it directly
  """
  def update(content, attrs) do
    content
    |> content.__struct__.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  find and update sourc
  """
  def find_update(queryable, id, attrs), do: do_find_update(queryable, id, attrs)
  def find_update(queryable, %{id: id} = attrs), do: do_find_update(queryable, id, attrs)

  defp do_find_update(queryable, id, attrs) do
    with {:ok, content} <- find(queryable, id) do
      content
      |> content.__struct__.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  find then update
  """
  def update_by(source, clauses, attrs) do
    with {:ok, content} <- find_by(source, clauses) do
      content
      |> Ecto.Changeset.change(attrs)
      |> Repo.update()
    end
  end

  def upsert_by(queryable, clauses, attrs) do
    case queryable |> find_by(clauses) do
      {:ok, content} ->
        content
        |> content.__struct__.changeset(attrs)
        |> Repo.update()

      {:error, _} ->
        queryable |> create(attrs)
    end
  end

  @doc """
  see https://elixirforum.com/t/ecto-inc-dec-update-one-helpers/5564
  """

  # def update_one(queryable, where, changes) do
  # query |> Ecto.Query.where(^where) |> Repo.update_all(set: changes)
  # end

  # def inc(queryable, where, changes) do
  #   query |> Ecto.Query.where(^where) |> Repo.update_all(inc: changes)
  # end

  def create(model, attrs) do
    model
    |> struct
    |> model.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  return the total count of a Modal based on id column
  also support filters
  """
  def count(queryable, filter \\ %{}) do
    queryable
    |> QueryBuilder.filter_pack(filter)
    |> select([f], count(f.id))
    |> Repo.one()
  end

  def next_count(queryable) do
    queryable |> count() |> add()
  end

  @doc """
  update meta info for article / comment
  """
  def update_meta(queryable, meta) do
    queryable
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:meta, meta)
    |> Repo.update()
  end

  @doc """
  update embed data
  """
  def update_embed(queryable, key, value) do
    queryable
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(key, value)
    |> Repo.update()
  end

  @doc "extract common articles info"
  @spec extract_articles(T.paged_data(), [Atom.t()]) :: T.paged_article_common()
  def extract_articles(%{entries: entries} = paged_articles, supported_threads) do
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
      title: article.title,
      upvotes_count: Map.get(article, :upvotes_count)
    }
  end
end
