defmodule MastaniServer.Accounts.Delegate.ReactedContents do
  @moduledoc """
  get contents(posts, jobs, videos ...) that user reacted (star, favorite ..)
  """
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import ShortMaps

  alias Helper.{ORM, QueryBuilder}
  alias MastaniServer.Accounts.User

  @doc """
  paged favorite contents of a spec category
  """
  def reacted_contents(thread, :favorite, category_id, ~m(page size)a = filter, %User{id: user_id}) do
    with {:ok, action} <- match_action(thread, :favorite) do
      action.reactor
      |> where([f], f.user_id == ^user_id)
      |> join(:inner, [f], p in assoc(f, ^thread))
      |> join(:inner, [f], c in assoc(f, :category))
      |> where([f, p, c], c.id == ^category_id)
      |> select([f, p], p)
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  @doc """
  paged favorited/stared contents
  """
  def reacted_contents(thread, react, ~m(page size)a = filter, %User{id: user_id}) do
    with {:ok, action} <- match_action(thread, react) do
      action.reactor
      |> where([f], f.user_id == ^user_id)
      |> join(:inner, [f], p in assoc(f, ^thread))
      |> select([f, p], p)
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  # def reacted_count(thread, react, %User{id: user_id}) do
  # with {:ok, action} <- match_action(thread, react) do
  # action.reactor
  # |> where([f], f.user_id == ^user_id)
  # |> group_by([f], f.post_id)
  # |> select([f], count(f.id))
  # end
  # end
end
