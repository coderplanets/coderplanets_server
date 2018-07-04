defmodule MastaniServer.Delivery.Delegate.Notifications do
  @moduledoc """
  The Delivery context.
  """
  import Ecto.Query, warn: false
  import Helper.Utils
  import ShortMaps

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.User
  alias MastaniServer.Delivery.{Notification, Record}
  alias Helper.ORM

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
  def fetch_notifications(%User{id: to_user_id} = user, %{page: page, size: size, read: read}) do
    {:ok, last_fetch_time} = get_last_fetch_time(:notification, read, user)

    query =
      Notification
      |> where([m], m.to_user_id == ^to_user_id)
      |> where([m], m.inserted_at > ^last_fetch_time)
      |> where([m], m.read == ^read)

    # |> order_by(asc: :inserted_at)
    notifications =
      query
      |> ORM.paginater(~m(page size)a)
      |> done()

    delete_items(:notification, query, notifications)
    record_operation(:notification, read, notifications)

    notifications
  end

  # TODO: refactor to common
  defp record_operation(:notification, _read, {:ok, %{entries: []}}), do: {:ok, ""}

  defp record_operation(:notification, read, {:ok, %{entries: entries}}) do
    first_insert = entries |> List.first() |> Map.get(:inserted_at)
    last_insert = entries |> List.last() |> Map.get(:inserted_at)

    recent_insert = Enum.min([first_insert, last_insert])
    # early_insert = Enum.max([first_insert, last_insert])

    last_fetch_time = recent_insert |> to_string
    user_id = entries |> List.first() |> Map.get(:to_user_id)

    attrs =
      case read do
        true ->
          %{user_id: user_id, notifications_record: %{last_fetch_read_time: last_fetch_time}}

        false ->
          %{user_id: user_id, notifications_record: %{last_fetch_unread_time: last_fetch_time}}
      end

    Record |> ORM.upsert_by([user_id: user_id], attrs)
  end

  defp get_last_fetch_time(:notification, read, %User{id: user_id}) do
    long_long_ago = Timex.shift(Timex.now(), years: -10)
    last_fetch_time = if read, do: "last_fetch_read_time", else: "last_fetch_unread_time"

    case Record |> ORM.find_by(user_id: user_id) do
      {:error, _} ->
        {:ok, long_long_ago}

      {:ok, record} ->
        record
        |> has_valid_value(:notifications_record)
        |> case do
          false ->
            {:ok, long_long_ago}

          true ->
            record
            |> Map.get(:notifications_record)
            |> Map.get(last_fetch_time, to_string(long_long_ago))
            |> NaiveDateTime.from_iso8601()
        end
    end
  end

  defp has_valid_value(map, key) when is_map(map) do
    Map.has_key?(map, key) and not is_nil(Map.get(map, key))
  end

  defp delete_items(:notification, _queryable, {:ok, %{entries: []}}), do: {:ok, ""}

  defp delete_items(:notification, queryable, {:ok, %{entries: entries}}) do
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
end
