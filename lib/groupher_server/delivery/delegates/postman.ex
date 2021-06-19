defmodule GroupherServer.Delivery.Delegate.Postman do
  @moduledoc """
  The Delivery context.
  """

  alias GroupherServer.Delivery.Delegate.{Mention, Notification}

  def send(:mention, artiment, mentions, from_user) do
    Mention.handle(artiment, mentions, from_user)
  end

  def send(:notify, attrs, from_user) do
    Notification.handle(attrs, from_user)
  end

  def fetch(:mention, user, filter) do
    Mention.paged_mentions(user, filter)
  end

  def fetch(:notification, user, filter) do
    Notification.paged_notifications(user, filter)
  end

  # def send(_, _, _), do: {:error, "delivery, not such service"}
  # def send(_, _, _, _), do: {:error, "delivery, not such service"}
end
