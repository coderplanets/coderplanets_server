defmodule MastaniServer.Accounts.Delegate.Search do
  @moduledoc """
  search for users
  """

  import Helper.Utils, only: [done: 1]
  import Ecto.Query, warn: false

  alias Helper.ORM
  alias MastaniServer.Accounts.User

  @search_items_count 15

  @doc """
  search community by title
  """
  def search_users(%{name: name} = _args) do
    User
    |> where([c], ilike(c.nickname, ^"%#{name}%"))
    |> ORM.paginater(page: 1, size: @search_items_count)
    |> done()
  end
end
