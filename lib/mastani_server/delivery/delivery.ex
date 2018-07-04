defmodule MastaniServer.Delivery do
  @moduledoc """
  The Delivery context.
  """
  alias MastaniServer.Delivery.Delegate.{Mentions, Notifications}

  # mentions
  defdelegate mention_someone(from_user, to_user, info), to: Mentions
  defdelegate fetch_mentions(user, filter), to: Mentions

  # notifications
  defdelegate notify_someone(from_user, to_user, info), to: Notifications
  defdelegate fetch_notifications(user, filter), to: Notifications

  # commons
  import Ecto.Query, warn: false
  alias MastaniServer.Repo

  alias MastaniServer.Delivery.{Notification, Mention, Record}
  alias MastaniServer.Accounts.User
  alias Helper.ORM

  def fetch_record(%User{id: user_id}), do: Record |> ORM.find_by(user_id: user_id)

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
      _ -> {:error, %{status: false}}
    end
  end

  def mark_read_all(%User{} = user, :notification) do
    query =
      Notification
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
end
