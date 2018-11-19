defmodule MastaniServer.CMS.Delegate.Search do
  @moduledoc """
  search for community, post, job ...
  """

  import Helper.Utils, only: [done: 1]
  import Ecto.Query, warn: false

  alias Helper.ORM
  alias MastaniServer.CMS.{Community}

  @doc """
  search community by title
  """
  def search_items(:community, %{title: title} = args) do
    Community
    |> where([c], ilike(c.title, ^"%#{title}%") or ilike(c.raw, ^"%#{title}%"))
    |> ORM.paginater(page: 1, size: 10)
    |> done()

    # from candidate in query,
    # where: like(candidate.first_name, ^("%#{text}%"))
  end
end
