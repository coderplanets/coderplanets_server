defmodule GroupherServer.Delivery.Delegate.Notification do
  @moduledoc """
  notification for upvote, comment, publish, collect, watch, follow an article or user
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, strip_struct: 1]
  import ShortMaps

  alias GroupherServer.{Accounts, Delivery, Repo}
  alias Delivery.Model.Notification
  alias Accounts.Model.User
  alias Helper.ORM

  @notify_group_interval_hour 1

  def handle(attrs, %User{} = from_user) do
    from_user = from_user |> Map.take([:login, :nickname]) |> Map.put(:user_id, from_user.id)

    case similar_action_in_latest_notify(attrs) do
      {:ok, notify} -> merge_notification(notify, from_user)
      {:error, _} -> create_notification(attrs, from_user)
    end
  end

  defp merge_notification(notify, from_user) do
    cur_from_users = notify.from_users |> Enum.map(&strip_struct(&1))
    from_users = (cur_from_users ++ [from_user]) |> Enum.uniq()

    notify
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:from_users, from_users)
    |> Repo.update()
  end

  defp create_notification(attrs, from_user) do
    %Notification{}
    |> Ecto.Changeset.change(attrs)
    |> Ecto.Changeset.put_embed(:from_users, [from_user])
    |> Repo.insert()
  end

  defp similar_action_in_latest_notify(%{comment_id: comment_id} = attrs)
       when not is_nil(comment_id) do
    ~m(user_id type article_id action comment_id)a = attrs
    n_hour_ago = Timex.shift(Timex.now(), hours: -@notify_group_interval_hour)

    from(n in Notification,
      where: n.inserted_at >= ^n_hour_ago,
      where: n.user_id == ^user_id,
      where: n.type == ^type,
      where: n.article_id == ^article_id,
      where: n.comment_id == ^comment_id,
      where: n.action == ^action,
      where: n.read == false
    )
    |> Repo.one()
    |> done
  end

  defp similar_action_in_latest_notify(attrs) do
    ~m(user_id type article_id action)a = attrs
    n_hour_ago = Timex.shift(Timex.now(), hours: -@notify_group_interval_hour)

    from(n in Notification,
      where: n.inserted_at >= ^n_hour_ago,
      where: n.user_id == ^user_id,
      where: n.type == ^type,
      where: n.article_id == ^article_id,
      where: n.action == ^action,
      where: n.read == false
    )
    |> Repo.one()
    |> done
  end

  def paged_notifications(user_id, %{page: page, size: size} = filter) do
    read = Map.get(filter, :read, false)

    Notification
    |> where([n], n.user_id == ^user_id)
    |> where([n], n.read == ^read)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end
end
