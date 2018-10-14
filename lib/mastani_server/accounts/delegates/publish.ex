defmodule MastaniServer.Accounts.Delegate.Publish do
  @moduledoc """
  user followers / following related
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  # import Helper.ErrorCode
  import ShortMaps

  import MastaniServer.CMS.Utils.Matcher

  alias Helper.{ORM, QueryBuilder}
  # alias MastaniServer.{Accounts, Repo}

  alias MastaniServer.Accounts.User
  # alias MastaniServer.CMS

  @doc """
  get paged published contets of a user
  """
  def published_contents(%User{id: user_id}, thread, %{page: page, size: size} = filter) do
    with {:ok, user} <- ORM.find(User, user_id),
         {:ok, content} <- match_action(thread, :self) do
      content.target
      |> join(:inner, [p], a in assoc(p, :author))
      |> where([p, a], a.user_id == ^user.id)
      |> select([p, a], p)
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end
end
