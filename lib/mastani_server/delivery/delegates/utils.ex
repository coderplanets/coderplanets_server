defmodule MastaniServer.Delivery.Delegate.Utils do
  @moduledoc """
  The Delivery context.
  """
  # commons
  import Ecto.Query, warn: false
  import Helper.Utils
  import ShortMaps

  alias MastaniServer.Repo

  alias MastaniServer.Delivery.{Notification, SysNotification, Mention, Record}
  alias MastaniServer.Accounts.User
  alias Helper.ORM

  def mailbox_status(%User{} = user) do
    filter = %{page: 1, size: 1, read: false}
    {:ok, mention_mail} = fetch_mails(user, Mention, filter)
    {:ok, notification_mail} = fetch_mails(user, Notification, filter)

    mention_count = mention_mail.total_entries
    notification_count = notification_mail.total_entries
    total_count = mention_count + notification_count

    has_mail = total_count > 0

    result = ~m(has_mail total_count mention_count notification_count)a
    {:ok, result}
  end

  def fetch_record(%User{id: user_id}), do: Record |> ORM.find_by(user_id: user_id)

  def mark_read_all(%User{} = user, :mention), do: Mention |> do_mark_read_all(user)
  def mark_read_all(%User{} = user, :notification), do: Notification |> do_mark_read_all(user)

  @doc """
  fetch mentions / notifications
  """
  def fetch_messages(:sys_notification, %User{} = user, %{page: page, size: size}) do
    {:ok, last_fetch_time} = get_last_fetch_time(SysNotification, user)

    mails =
      SysNotification
      |> order_by(desc: :inserted_at)
      |> where([m], m.inserted_at > ^last_fetch_time)
      |> ORM.paginater(~m(page size)a)
      |> done()

    record_operation(user, SysNotification, mails)
    mails
  end

  def fetch_messages(%User{} = user, queryable, %{page: _page, size: _size, read: read} = filter) do
    mails = fetch_mails_and_delete(user, queryable, filter)
    record_operation(queryable, read, mails)

    mails
  end

  defp fetch_mails(user, queryable, %{page: page, size: size, read: read}) do
    {:ok, last_fetch_time} = get_last_fetch_time(queryable, read, user)

    queryable
    |> where([m], m.to_user_id == ^user.id)
    |> where([m], m.inserted_at > ^last_fetch_time)
    |> where([m], m.read == ^read)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  defp fetch_mails_and_delete(user, queryable, %{page: page, size: size, read: read}) do
    {:ok, last_fetch_time} = get_last_fetch_time(queryable, read, user)

    query =
      queryable
      |> where([m], m.to_user_id == ^user.id)
      |> where([m], m.inserted_at > ^last_fetch_time)
      |> where([m], m.read == ^read)

    mails =
      query
      |> order_by(desc: :inserted_at)
      |> ORM.paginater(~m(page size)a)
      |> done()

    delete_items(query, mails)

    mails
  end

  defp record_operation(Mention, _read, {:ok, %{entries: []}}), do: {:ok, ""}
  defp record_operation(Notification, _read, {:ok, %{entries: []}}), do: {:ok, ""}
  defp record_operation(_, SysNotification, {:ok, %{entries: []}}), do: {:ok, ""}

  defp record_operation(Mention, read, {:ok, %{entries: entries}}) do
    do_record_operation(:mentions_record, read, {:ok, %{entries: entries}})
  end

  defp record_operation(Notification, read, {:ok, %{entries: entries}}) do
    do_record_operation(:notifications_record, read, {:ok, %{entries: entries}})
  end

  defp record_operation(%User{} = user, SysNotification, {:ok, %{entries: entries}}) do
    do_record_operation(user, :sys_notifications_record, {:ok, %{entries: entries}})
  end

  defp get_record_lasttime(entries) do
    first_insert = entries |> List.first() |> Map.get(:inserted_at)
    last_insert = entries |> List.last() |> Map.get(:inserted_at)
    newest_insert = Enum.max([first_insert, last_insert])

    newest_insert |> Timex.to_datetime() |> to_string
  end

  # sys_notification
  defp do_record_operation(%User{id: user_id}, record_name, {:ok, %{entries: entries}}) do
    record_last_fetch_time = get_record_lasttime(entries)

    attrs =
      %{user_id: user_id} |> Map.put(record_name, %{last_fetch_time: record_last_fetch_time})

    Record |> ORM.upsert_by([user_id: user_id], attrs)
  end

  # last_fetch_read_time
  # > the last fetch time of mails that is read
  # last_fetch_unread_time
  # > the last fetch time of mails that is read
  defp do_record_operation(record_name, read, {:ok, %{entries: entries}}) do
    record_last_fetch_time = get_record_lasttime(entries)
    user_id = entries |> List.first() |> Map.get(:to_user_id)

    attrs =
      case read do
        true ->
          %{user_id: user_id}
          |> Map.put(record_name, %{last_fetch_read_time: record_last_fetch_time})

        false ->
          %{user_id: user_id}
          |> Map.put(record_name, %{last_fetch_unread_time: record_last_fetch_time})
      end

    Record |> ORM.upsert_by([user_id: user_id], attrs)
  end

  defp get_last_fetch_time(Mention, read, user) do
    timekey = get_record_lasttime_key(read)
    do_get_last_fetch_time(:mentions_record, user, timekey)
  end

  defp get_last_fetch_time(Notification, read, user) do
    timekey = get_record_lasttime_key(read)
    do_get_last_fetch_time(:notifications_record, user, timekey)
  end

  defp get_last_fetch_time(SysNotification, user) do
    timekey = get_record_lasttime_key(:sys_notifications_record)
    do_get_last_fetch_time(:sys_notifications_record, user, timekey)
  end

  defp get_record_lasttime_key(:sys_notifications_record) do
    "last_fetch_time"
  end

  defp get_record_lasttime_key(read) do
    case read do
      true -> "last_fetch_read_time"
      false -> "last_fetch_unread_time"
    end
  end

  defp do_get_last_fetch_time(record_key, %User{id: user_id}, timekey) do
    long_long_ago = Timex.shift(Timex.now(), years: -10)

    case Record |> ORM.find_by(user_id: user_id) do
      {:error, _} ->
        {:ok, long_long_ago}

      {:ok, record} ->
        record
        |> has_valid_value(record_key)
        |> case do
          false ->
            {:ok, long_long_ago}

          true ->
            record
            |> Map.get(record_key)
            |> Map.get(timekey, to_string(long_long_ago))
            |> NaiveDateTime.from_iso8601()
        end
    end
  end

  defp delete_items(_queryable, {:ok, %{entries: []}}), do: {:ok, ""}
  defp delete_items(_queryable, {:ok, %{entries: []}}), do: {:ok, ""}

  defp delete_items(queryable, {:ok, %{entries: entries}}) do
    # delete_all only support queryable and where syntax
    # TODO: move logic to queue job

    first_id = entries |> List.first() |> Map.get(:id)
    last_id = entries |> List.last() |> Map.get(:id)

    min_id = Enum.min([first_id, last_id])
    max_id = Enum.max([first_id, last_id])

    queryable
    |> where([m], m.id >= ^min_id and m.id <= ^max_id)
    |> Repo.delete_all()
  end

  defp do_mark_read_all(queryable, %User{} = user) do
    query =
      queryable
      |> where([m], m.to_user_id == ^user.id)

    try do
      Repo.update_all(
        query,
        set: [read: true]
      )

      {:ok, %{status: true}}
    rescue
      _ -> {:error, %{status: false}}
    end
  end

  defp has_valid_value(map, key) when is_map(map) do
    Map.has_key?(map, key) and not is_nil(Map.get(map, key))
  end
end
