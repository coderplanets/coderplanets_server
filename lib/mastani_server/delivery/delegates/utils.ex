defmodule MastaniServer.Delivery.Delegate.Utils do
  @moduledoc """
  The Delivery context.
  """
  # commons
  import Ecto.Query, warn: false
  import Helper.Utils
  import ShortMaps

  alias MastaniServer.Repo

  alias MastaniServer.Delivery.{Notification, Mention, Record}
  alias MastaniServer.Accounts.User
  alias Helper.ORM

  def fetch_record(%User{id: user_id}), do: Record |> ORM.find_by(user_id: user_id)

  def mark_read_all(%User{} = user, :mention), do: Mention |> do_mark_read_all(user)
  def mark_read_all(%User{} = user, :notification), do: Notification |> do_mark_read_all(user)

  @doc """
  fetch mentions / notifications
  """
  def fetch_messages(%User{} = user, queryable, %{page: page, size: size, read: read}) do
    {:ok, last_fetch_time} = get_last_fetch_time(queryable, read, user)

    query =
      queryable
      |> where([m], m.to_user_id == ^user.id)
      |> where([m], m.inserted_at > ^last_fetch_time)
      |> where([m], m.read == ^read)

    # |> order_by(asc: :inserted_at)
    messages =
      query
      |> ORM.paginater(~m(page size)a)
      |> done()

    delete_items(query, messages)
    record_operation(queryable, read, messages)

    messages
  end

  defp record_operation(Mention, _read, {:ok, %{entries: []}}), do: {:ok, ""}
  defp record_operation(Notification, _read, {:ok, %{entries: []}}), do: {:ok, ""}

  defp record_operation(Mention, read, {:ok, %{entries: entries}}) do
    do_record_operation(:mentions_record, read, {:ok, %{entries: entries}})
  end

  defp record_operation(Notification, read, {:ok, %{entries: entries}}) do
    do_record_operation(:notifications_record, read, {:ok, %{entries: entries}})
  end

  defp do_record_operation(record_name, read, {:ok, %{entries: entries}}) do
    first_insert = entries |> List.first() |> Map.get(:inserted_at)
    last_insert = entries |> List.last() |> Map.get(:inserted_at)

    recent_insert = Enum.min([first_insert, last_insert])
    # early_insert = Enum.max([first_insert, last_insert])

    last_fetch_time = recent_insert |> to_string
    user_id = entries |> List.first() |> Map.get(:to_user_id)

    # %{user_id: user_id, mentions_record: %{last_fetch_time: last_fetch_time}}

    attrs =
      case read do
        true ->
          # %{user_id: user_id, mentions_record: %{last_fetch_read_time: last_fetch_time}}
          %{user_id: user_id} |> Map.put(record_name, %{last_fetch_read_time: last_fetch_time})

        false ->
          # %{user_id: user_id, mentions_record: %{last_fetch_unread_time: last_fetch_time}}
          %{user_id: user_id} |> Map.put(record_name, %{last_fetch_unread_time: last_fetch_time})
      end

    Record |> ORM.upsert_by([user_id: user_id], attrs)
  end

  defp get_last_fetch_time(Mention, read, user) do
    do_get_last_fetch_time(:mentions_record, read, user)
  end

  defp get_last_fetch_time(Notification, read, user) do
    do_get_last_fetch_time(:notifications_record, read, user)
  end

  defp do_get_last_fetch_time(record_key, read, %User{id: user_id}) do
    long_long_ago = Timex.shift(Timex.now(), years: -10)
    last_fetch_time = if read, do: "last_fetch_read_time", else: "last_fetch_unread_time"

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
            |> Map.get(last_fetch_time, to_string(long_long_ago))
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
