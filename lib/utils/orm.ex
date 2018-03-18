defmodule MastaniServer.Utils.ORM do
  @moduledoc """
  General update or delete content
  """
  import Ecto.Query, warn: false
  import MastaniServer.Utils.Helper, only: [done: 1, done: 3]

  alias MastaniServer.Repo
  alias MastaniServer.Utils.QueryBuilder

  @doc """
  a wrap for paginate request
  """
  def paginater(queryable, page: page, size: size) do
    queryable |> Repo.paginate(page: page, page_size: size)
  end

  @doc """
  return pageinated Data required by filter
  """
  def read_all(queryable, %{page: page, size: size} = filter) do
    queryable
    |> QueryBuilder.filter_pack(filter)
    |> paginater(page: page, size: size)
    |> done()
  end

  @doc """
  return  Data required by filter
  """
  def read_all(queryable, filter) do
    queryable |> QueryBuilder.filter_pack(filter) |> Repo.all() |> done()
  end

  # def read_quiet(queryable, id), do: not inc_views_count
  @doc """
  Require queryable has a views fields to count the views of the queryable Modal
  if queryable NOT contains views fields consider use read_quiet/2
  """
  def read(queryable, id) do
    with {:ok, result} <- find(queryable, id) do
      result |> inc_views_count(queryable) |> done()
    end
  end

  defp inc_views_count(content, queryable) do
    {1, [result]} =
      Repo.update_all(
        from(p in queryable, where: p.id == ^content.id),
        [inc: [views: 1]],
        returning: [:views]
      )

    put_in(content.views, result.views)
  end

  @doc """
  NOTICE: this should be use together with Authorize/OwnerCheck etc Middleware
  DO NOT use it directly
  """
  def delete(content), do: Repo.delete(content)

  def find_delete(queryable, id) do
    with {:ok, content} <- find(queryable, id) do
      delete(content)
    end
  end

  @doc """
  NOTICE: this should be use together with Authorize/OwnerCheck etc Middleware
  DO NOT use it directly
  """
  def update(content, attrs) do
    content
    |> content.__struct__.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  wrap Repo.get with result/errer format handle
  """
  def find(queryable, id, preload: preload) do
    queryable
    |> preload(^preload)
    |> Repo.get(id)
    |> done(queryable, id)
  end

  def find(queryable, id) do
    queryable
    |> Repo.get(id)
    |> done(queryable, id)
  end

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

  defp not_found_formater(queryable, id) when is_integer(id) or is_binary(id) do
    modal_sortname = queryable |> to_string |> String.split(".") |> List.last()
    "#{modal_sortname}(#{id}) not found"
  end

  defp not_found_formater(queryable, clauses) do
    modal_sortname = queryable |> to_string |> String.split(".") |> List.last()

    detail =
      clauses
      |> Enum.into(%{})
      |> Map.values()
      |> List.first()
      |> to_string

    "#{modal_sortname}(#{detail}) not found"
  end
end
