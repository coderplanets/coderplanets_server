defmodule MastaniServer.Utils.ORM do
  @moduledoc """
  General update or delete content
  """
  import Ecto.Query, warn: false
  import MastaniServer.Utils.Helper

  alias MastaniServer.Repo
  alias MastaniServer.Utils.QueryPuzzle

  @doc """
  # TODO: 隐式的检查 queryable 是否合法
  """
  def read_all(queryable, %{page: page, size: size} = filter) do
    # filters = filters |> Map.delete(:page) |> Map.delete(:size)
    # with {:ok, action} <- match_action(part, react) do
    queryable
    |> QueryPuzzle.filter_pack(filter)
    |> paginater(page: page, size: size)
    |> done()

    # end
  end

  @doc """
  # TODO: 隐式的检查 queryable 是否合法
  """
  def read_all(queryable, filter) do
    # with {:ok, action} <- match_action(part, react) do
    queryable |> QueryPuzzle.filter_pack(filter) |> Repo.all() |> done()
    # end
  end

  # def read_quiet(queryable, id), do: not inc_views_count
  @doc """
  Require queryable has a views fields to count the views of the queryable Modal
  if queryable NOT contains views fields consider use read_quiet/2
  # TODO: 隐式的检查 queryable 是否合法
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
