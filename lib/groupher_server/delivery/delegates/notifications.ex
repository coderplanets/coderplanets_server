defmodule GroupherServer.Delivery.Delegate.Notifications do
  @moduledoc """
  The Delivery context.
  """
  import Helper.Utils, only: [done: 2]

  alias GroupherServer.{Accounts, Delivery}

  alias Accounts.Model.User
  alias Delivery.Model.{Notification, SysNotification}
  alias Delivery.Delegate.Utils
  alias Helper.ORM

  # TODO: audience
  def publish_system_notification(info) do
    attrs = %{
      source_id: info.source_id,
      source_title: info.source_title,
      source_type: info |> Map.get(:source_type, ""),
      source_preview: info |> Map.get(:source_preview, "")
    }

    SysNotification |> ORM.create(attrs) |> done(:status)
  end

  def notify_someone(%User{id: from_user_id}, %User{id: to_user_id}, info) do
    attrs = %{
      from_user_id: from_user_id,
      to_user_id: to_user_id,
      action: info.action,
      source_id: info.source_id,
      source_title: info.source_title,
      source_type: info.source_type,
      source_preview: info.source_preview
    }

    Notification |> ORM.create(attrs)
  end

  @doc """
  fetch notifications from Delivery
  """
  def fetch_notifications(%User{} = user, %{page: _, size: _, read: _} = filter) do
    Utils.fetch_messages(user, Notification, filter)
  end

  def fetch_sys_notifications(%User{} = user, %{page: _, size: _} = filter) do
    Utils.fetch_messages(:sys_notification, user, filter)
  end
end
