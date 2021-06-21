defmodule GroupherServer.Delivery.Delegate.Postman do
  @moduledoc """
  The Delivery context.
  """

  alias GroupherServer.Delivery.Delegate.{Mention, Notification}

  def send(:mention, artiment, mentions, from_user) do
    Mention.handle(artiment, mentions, from_user)
  end

  def send(:notify, attrs, from_user), do: Notification.handle(attrs, from_user)
  def revoke(:notify, attrs, from_user), do: Notification.revoke(attrs, from_user)

  def fetch(:mention, user, filter), do: Mention.paged_mentions(user, filter)
  def fetch(:notification, user, filter), do: Notification.paged_notifications(user, filter)

  def unread_count(:mention, user_id), do: Mention.unread_count(user_id)
  def unread_count(:notification, user_id), do: Notification.unread_count(user_id)

  def mark_read(:mention, ids, user), do: Mention.mark_read(ids, user)
  def mark_read(:notification, ids, user), do: Notification.mark_read(ids, user)

  def mark_read_all(:mention, user), do: Mention.mark_read_all(user)
  def mark_read_all(:notification, user), do: Notification.mark_read_all(user)

  # def send(_, _, _), do: {:error, "delivery, not such service"}
  # def send(_, _, _, _), do: {:error, "delivery, not such service"}
end
