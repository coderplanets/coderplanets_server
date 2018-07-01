defmodule MastaniServer.Delivery do
  @moduledoc """
  The Delivery context.
  """
  import Ecto.Query, warn: false
  import Helper.Utils
  import ShortMaps

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.User
  alias MastaniServer.Delivery.{Mention, Record}
  alias Helper.ORM

  def mention_someone(%User{id: from_user_id}, %User{id: to_user_id}, info) do
    attrs = %{
      from_user_id: from_user_id,
      to_user_id: to_user_id,
      source_id: info.source_id,
      source_title: info.source_title,
      source_type: info.source_type,
      source_preview: info.source_preview
    }

    Mention |> ORM.create(attrs)
  end

  @doc """
  fetch mentions from Delivery stop
  """
  def fetch_mentions(%User{id: to_user_id} = user, %{page: page, size: size, read: read}) do
    {:ok, last_fetch_time} = get_last_fetch_time(:mention, read, user)

    query =
      Mention
      |> where([m], m.to_user_id == ^to_user_id)
      |> where([m], m.inserted_at > ^last_fetch_time)
      |> where([m], m.read == ^read)

    # |> order_by(asc: :inserted_at)
    mentions =
      query
      |> ORM.paginater(~m(page size)a)
      |> done()

    delete_items(:mention, query, mentions)
    record_operation(:mention, read, mentions)

    mentions
  end

  def mark_read_all(%User{} = user, :mention) do
    query =
      Mention
      |> where([m], m.to_user_id == ^user.id)

    try do
      Repo.update_all(
        query,
        set: [read: true]
      )

      {:ok, %{status: true}}
    rescue
      e -> {:error, %{status: false}}
    end
  end

  defp record_operation(:mention, _read, {:ok, %{entries: []}}), do: {:ok, ""}

  defp record_operation(:mention, read, {:ok, %{entries: entries}}) do
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
          %{user_id: user_id, mentions_record: %{last_fetch_read_time: last_fetch_time}}

        false ->
          %{user_id: user_id, mentions_record: %{last_fetch_unread_time: last_fetch_time}}
      end

    Record |> ORM.upsert_by([user_id: user_id], attrs)
  end

  # TODO: which_part?
  def fetch_record(%User{id: user_id}) do
    Record |> ORM.find_by(user_id: user_id)
    # Record
  end

  defp get_last_fetch_time(:mention, read, %User{id: user_id}) do
    long_long_ago = Timex.shift(Timex.now(), years: -10)
    last_fetch_time = if read, do: "last_fetch_read_time", else: "last_fetch_unread_time"

    case Record |> ORM.find_by(user_id: user_id) do
      {:error, _} ->
        {:ok, long_long_ago}

      {:ok, record} ->
        record
        |> Map.has_key?(:mentions_record)
        |> case do
          false ->
            {:ok, long_long_ago}

          true ->
            record
            |> Map.get(:mentions_record)
            |> Map.get(last_fetch_time, to_string(long_long_ago))
            |> NaiveDateTime.from_iso8601()
        end
    end
  end

  def mark_mention(%Mention{id: mid}, :read_or_unread) do
    IO.inspect(mid, label: "mark mention")
  end

  defp delete_items(:mention, _queryable, {:ok, %{entries: []}}), do: {:ok, ""}

  defp delete_items(:mention, queryable, {:ok, %{entries: entries}}) do
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
