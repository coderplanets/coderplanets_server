defmodule GroupherServer.Accounts.Delegate.Mailbox do
  import Ecto.Query, warn: false

  alias GroupherServer.{Accounts, Delivery}
  alias Accounts.Model.User
  alias Helper.ORM

  def update_mailbox_status(user_id) do
    with {:ok, user} <- ORM.find(User, user_id),
         {:ok, unread_mentions_count} <- Delivery.unread_count(:mention, user_id),
         {:ok, unread_notifications_count} <- Delivery.unread_count(:notification, user_id) do
      unread_total_count = unread_mentions_count + unread_notifications_count
      is_empty = unread_total_count < 1

      mailbox = %{
        unread_mentions_count: unread_mentions_count,
        unread_notifications_count: unread_notifications_count,
        unread_total_count: unread_total_count,
        is_empty: is_empty
      }

      user |> ORM.update_embed(:mailbox, mailbox)
    end
  end
end
