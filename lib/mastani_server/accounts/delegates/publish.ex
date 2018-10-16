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
      |> join(:inner, [content], author in assoc(content, :author))
      |> where([content, author], author.user_id == ^user.id)
      |> select([content, author], content)
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  @doc """
  get paged published comments of a user
  """
  def published_comments(%User{id: user_id}, thread, %{page: page, size: size} = filter) do
    with {:ok, user} <- ORM.find(User, user_id),
         {:ok, content} <- match_action(thread, :comment) do
      content.reactor
      |> join(:inner, [comment], author in assoc(comment, :author))
      |> where([comment, author], author.id == ^user.id)
      |> select([comment, author], comment)
      |> QueryBuilder.filter_pack(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end
end
