defmodule MastaniServer.Utils.ORM do
  @moduledoc """
  General update or delete content
  """
  import Ecto.Query, warn: false
  import MastaniServer.Utils.Helper

  alias MastaniServer.Repo
  alias MastaniServer.Utils.QueryBuilder

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

  @doc """
  NOTICE: this should be use together with Authorize/OwnerCheck etc Middleware
  DO NOT use it directly
  """
  def update(content, attrs) do
    content
    |> content.__struct__.changeset(attrs)
    |> Repo.update()
  end
end
