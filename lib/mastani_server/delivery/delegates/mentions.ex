defmodule MastaniServer.Delivery.Delegate.Mentions do
  @moduledoc """
  The Delivery context.
  """
  import Helper.Utils, only: [done: 2]

  alias MastaniServer.Accounts.User
  alias MastaniServer.Delivery.Mention
  alias Helper.ORM

  alias MastaniServer.Delivery.Delegate.Utils

  def mention_someone(%User{id: from_user_id}, %User{id: to_user_id}, info) do
    attrs = %{
      from_user_id: from_user_id,
      to_user_id: to_user_id,
      source_id: info.source_id,
      source_title: info.source_title,
      source_type: info.source_type,
      source_preview: info.source_preview
    }

    Mention
    |> ORM.create(attrs)
    |> done(:status)
  end

  @doc """
  fetch mentions from Delivery stop
  """
  def fetch_mentions(%User{} = user, %{page: _, size: _, read: _} = filter) do
    Utils.fetch_messages(user, Mention, filter)
  end
end
