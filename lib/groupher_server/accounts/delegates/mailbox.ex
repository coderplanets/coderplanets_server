defmodule GroupherServer.Accounts.Delegate.Mailbox do
  import Ecto.Query, warn: false

  import Helper.Utils, only: [done: 1]

  alias GroupherServer.{Accounts, Delivery}

  alias Accounts.Model.{Embeds, User}
  alias Helper.ORM

  @default_mailbox_status Embeds.UserMailbox.default_status()

  def mailbox_status(%User{mailbox: nil}), do: @default_mailbox_status |> done
  def mailbox_status(%User{mailbox: mailbox}), do: mailbox |> done

  def mark_read(type, ids, %User{} = user) do
    Delivery.mark_read(type, ids, user)
  end

  def mark_read_all(type, %User{} = user), do: Delivery.mark_read_all(type, user)

  def paged_mailbox_messages(type, user, filter) do
    Delivery.fetch(type, user, filter)
  end

  @doc "update messages count in mailbox"
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
