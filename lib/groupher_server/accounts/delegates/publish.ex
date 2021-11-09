defmodule GroupherServer.Accounts.Delegate.Publish do
  @moduledoc """
  user followers / following related
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [ensure: 2, plural: 1]

  alias GroupherServer.{Accounts, CMS}
  alias Accounts.Model.{Embeds, User}

  alias Helper.ORM

  @default_meta Embeds.UserMeta.default_meta()

  @doc """
  get paged published contets of a user
  """
  def paged_published_articles(%User{id: user_id}, thread, filter) do
    CMS.paged_published_articles(thread, filter, user_id)
  end

  @doc """
  update published articles count in user meta
  """
  def update_published_states(user_id, thread) do
    filter = %{page: 1, size: 1}

    with {:ok, user} <- ORM.find(User, user_id),
         {:ok, paged_articles} <- CMS.paged_published_articles(thread, filter, user_id) do
      #
      user_meta = ensure(user.meta, @default_meta)
      meta = Map.put(user_meta, :"published_#{plural(thread)}_count", paged_articles.total_count)

      ORM.update_meta(user, meta)
    end
  end

  def paged_published_comments(user, filter) do
    CMS.paged_published_comments(user, filter)
  end

  def paged_published_comments(user, thread, filter) do
    CMS.paged_published_comments(user, thread, filter)
  end
end
