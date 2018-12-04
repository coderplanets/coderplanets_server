defmodule MastaniServer.Accounts.Delegate.Mails do
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, done: 2]
  import ShortMaps

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.{User, MentionMail, NotificationMail, SysNotificationMail}
  alias MastaniServer.Delivery
  alias Helper.ORM

  def mailbox_status(%User{} = user), do: Delivery.mailbox_status(user)

  def fetch_mentions(%User{} = user, filter) do
    with {:ok, mentions} <- Delivery.fetch_mentions(user, filter),
         {:ok, washed_mentions} <- wash_data(MentionMail, mentions.entries) do
      MentionMail |> Repo.insert_all(washed_mentions)
      MentionMail |> messages_fetcher(washed_mentions, user, filter)
    end
  end

  def fetch_notifications(%User{} = user, filter) do
    with {:ok, notifications} <- Delivery.fetch_notifications(user, filter),
         {:ok, washed_notifications} <- wash_data(NotificationMail, notifications.entries) do
      NotificationMail |> Repo.insert_all(washed_notifications)
      NotificationMail |> messages_fetcher(washed_notifications, user, filter)
    end
  end

  def fetch_sys_notifications(%User{} = user, %{page: page, size: size, read: read}) do
    with {:ok, sys_notifications} <-
           Delivery.fetch_sys_notifications(user, %{page: page, size: size}),
         {:ok, washed_notifications} <-
           wash_data(SysNotificationMail, user, sys_notifications.entries) do
      SysNotificationMail
      |> Repo.insert_all(washed_notifications)

      SysNotificationMail
      |> order_by(desc: :inserted_at)
      |> where([m], m.user_id == ^user.id)
      |> where([m], m.read == ^read)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  defp messages_fetcher(queryable, _washed_data, %User{id: user_id}, %{
         page: page,
         size: size,
         read: read
       }) do
    queryable
    |> order_by(desc: :inserted_at)
    |> where([m], m.to_user_id == ^user_id)
    |> where([m], m.read == ^read)
    |> preload(:from_user)
    |> preload(:to_user)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  def mark_mail_read(%MentionMail{id: id}, %User{} = user) do
    do_mark_mail_read(MentionMail, id, user)
  end

  def mark_mail_read(%NotificationMail{id: id}, %User{} = user) do
    do_mark_mail_read(NotificationMail, id, user)
  end

  def mark_mail_read(%SysNotificationMail{id: id}, %User{} = user) do
    with {:ok, mail} <- SysNotificationMail |> ORM.find_by(id: id, user_id: user.id) do
      mail |> ORM.update(%{read: true}) |> done(:status)
    end
  end

  def mark_mail_read_all(%User{} = user, :mention) do
    user |> do_mark_mail_read_all(MentionMail, :mention)
  end

  def mark_mail_read_all(%User{} = user, :notification) do
    user |> do_mark_mail_read_all(NotificationMail, :notification)
  end

  defp do_mark_mail_read(queryable, id, %User{} = user) do
    with {:ok, mail} <- queryable |> ORM.find_by(id: id, to_user_id: user.id) do
      mail |> ORM.update(%{read: true}) |> done(:status)
    end
  end

  defp do_mark_mail_read_all(%User{} = user, mail, atom) do
    query =
      mail
      |> where([m], m.to_user_id == ^user.id)

    Repo.update_all(query, set: [read: true])

    Delivery.mark_read_all(user, atom)
  end

  defp wash_data(MentionMail, []), do: {:ok, []}
  defp wash_data(NotificationMail, []), do: {:ok, []}

  defp wash_data(MentionMail, list), do: do_wash_data(list)
  defp wash_data(NotificationMail, list), do: do_wash_data(list)

  defp wash_data(SysNotificationMail, user, list) do
    convert =
      list
      |> Enum.map(
        &(Map.from_struct(&1)
          |> Map.delete(:__meta__)
          |> Map.put(:user_id, user.id))
      )

    {:ok, convert}
  end

  defp do_wash_data(list) do
    convert =
      list
      |> Enum.map(
        &(Map.from_struct(&1)
          |> Map.delete(:__meta__)
          |> Map.delete(:id)
          |> Map.delete(:from_user)
          |> Map.delete(:to_user))
      )

    {:ok, convert}
  end
end
