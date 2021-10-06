defmodule GroupherServer.Delivery.Delegate.Notification do
  @moduledoc """
  notification for upvote, comment, publish, collect, watch, follow an article or user
  """
  import Ecto.Query, warn: false

  import Helper.Utils,
    only: [get_config: 2, done: 1, strip_struct: 1, atom_values_to_upcase: 1]

  import ShortMaps

  alias GroupherServer.{Accounts, Delivery, Repo}
  alias Delivery.Model.Notification
  alias Accounts.Model.User

  alias Helper.ORM
  alias Ecto.Multi

  @notify_actions get_config(:general, :nofity_actions)
  @notify_group_interval_hour get_config(:general, :notify_group_interval_hour)
  @cut_from_users_count 3

  def handle(%{action: action, user_id: user_id} = attrs, %User{} = from_user) do
    with true <- action in @notify_actions,
         true <- is_valid?(attrs),
         true <- user_id !== from_user.id do
      Multi.new()
      |> Multi.run(:upsert_notifications, fn _, _ ->
        from_user =
          from_user
          |> Map.take([:login, :nickname])
          |> Map.put(:user_id, from_user.id)

        case find_exist_notify(attrs, :latest_peroid) do
          {:ok, notify} -> merge_notification(notify, from_user)
          {:error, _} -> create_notification(attrs, from_user)
        end
      end)
      |> Multi.run(:update_user_mailbox_status, fn _, %{upsert_notifications: nofity} ->
        Accounts.update_mailbox_status(nofity.user_id)
      end)
      |> Repo.transaction()
      |> result()
    else
      false -> {:error, "invalid args for notification"}
      error -> error
    end
  end

  @doc "revoke action in notification in all history"
  def revoke(attrs, %User{} = from_user) do
    attrs = attrs |> Map.put(:from_user, from_user)

    with {:ok, notifications} <- find_exist_notify(attrs, :all) do
      Multi.new()
      |> Multi.run(:revoke_notifications, fn _, _ ->
        Enum.each(notifications, fn notify ->
          case length(notify.from_users) == 1 do
            # 只有一就删除记录
            true ->
              ORM.delete(notify)

            # 如果是多人集合就在 from_users 中删除该用户
            false ->
              from_users = Enum.reject(notify.from_users, &(&1.login == from_user.login))
              notify |> ORM.update_embed(:from_users, from_users)
          end
        end)
        |> done
      end)
      |> Multi.run(:update_user_mailbox_status, fn _, _ ->
        Enum.each(notifications, &Accounts.update_mailbox_status(&1.user_id)) |> done
      end)
      |> Repo.transaction()
      |> result()
    else
      false -> {:ok, :pass}
      {:error, _} -> {:ok, :pass}
    end
  end

  def paged_notifications(%User{} = user, %{page: page, size: size} = filter) do
    read = Map.get(filter, :read, false)

    Notification
    |> where([n], n.user_id == ^user.id and n.read == ^read)
    |> ORM.paginator(~m(page size)a)
    |> cut_from_users_ifneed
    |> done
  end

  # @cut_from_users_count
  defp cut_from_users_ifneed(%{entries: entries} = paged_contents) do
    entries =
      Enum.map(entries, fn notify ->
        from_users = Enum.slice(notify.from_users, 0, @cut_from_users_count)
        notify |> Map.put(:from_users, from_users)
      end)

    paged_contents |> Map.put(:entries, entries)
  end

  # 注意这里并不是准确的 count, 因为可能有短时间内 merge 到一起的通知
  def unread_count(user_id) do
    Notification
    |> where([n], n.user_id == ^user_id and n.read == false)
    |> ORM.count()
  end

  @doc "mark notification in ids as readed"
  def mark_read(ids, %User{} = user) when is_list(ids) do
    Notification
    |> where([m], m.id in ^ids and m.user_id == ^user.id and m.read == false)
    |> ORM.mark_read_all()
  end

  @doc "mark all related notifications as readed"
  def mark_read_all(%User{} = user) do
    Notification
    |> where([m], m.user_id == ^user.id and m.read == false)
    |> ORM.mark_read_all()
  end

  # 如果在临近时间段内有类似操作，直接将这次的操作人添加到 from_users 中即可
  # 避免对统一操作的大量重复消息提醒，体验不好
  defp merge_notification(notify, from_user) do
    cur_from_users = notify.from_users |> Enum.map(&strip_struct(&1))
    from_users = ([from_user] ++ cur_from_users) |> Enum.uniq()

    notify
    |> ORM.update_embed(:from_users, from_users, %{from_users_count: length(from_users)})
  end

  # 创建通知
  defp create_notification(attrs, from_user) do
    attrs = attrs |> Map.merge(%{from_users_count: 1}) |> atom_values_to_upcase

    %Notification{}
    |> Ecto.Changeset.change(attrs)
    |> Ecto.Changeset.put_embed(:from_users, [from_user])
    |> Repo.insert()
  end

  defp find_exist_notify(%{action: :follow} = attrs, opt) do
    do_find_exist_notify(Notification, attrs, opt)
  end

  defp find_exist_notify(%{comment_id: comment_id} = attrs, opt)
       when not is_nil(comment_id) do
    ~m(thread article_id comment_id)a = atom_values_to_upcase(attrs)

    Notification
    |> where(
      [n],
      n.thread == ^thread and n.article_id == ^article_id and n.comment_id == ^comment_id
    )
    |> do_find_exist_notify(attrs, opt)
  end

  defp find_exist_notify(attrs, opt) do
    ~m(thread article_id)a = atom_values_to_upcase(attrs)

    Notification
    |> where([n], n.thread == ^thread and n.article_id == ^article_id)
    |> do_find_exist_notify(attrs, opt)
  end

  # find exist notification, in latest peroid
  # 在最近的时期内，找到一个存在的通知
  @spec do_find_exist_notify(Ecto.Queryable.t(), Map.t(), Atom.t()) ::
          {Atom.t(), Notification.t()}
  defp do_find_exist_notify(queryable, attrs, :latest_peroid) do
    ~m(user_id action)a = atom_values_to_upcase(attrs)

    queryable
    |> where([n], n.inserted_at >= ^interval_threshold_time() and n.user_id == ^user_id)
    |> where([n], n.action == ^action and n.read == false)
    |> Repo.one()
    |> done
  end

  # find exist notifications, in all history
  # 在所有通知中，找到多个存在的通知
  @spec do_find_exist_notify(Ecto.Queryable.t(), Map.t(), Atom.t()) ::
          {Atom.t(), [Notification.t()]}
  defp do_find_exist_notify(queryable, attrs, _opt) do
    ~m(user_id action from_user)a = atom_values_to_upcase(attrs)

    queryable = queryable |> where([n], n.user_id == ^user_id and n.action == ^action)

    # select login in from_users
    # see https://stackoverflow.com/questions/51267155/in-postgresql-how-can-i-select-rows-where-a-jsonb-array-contains-objects
    # see https://elixirforum.com/t/writing-queries-with-multiple-from-clauses/28646/2?u=mydearxym
    from(n in queryable,
      cross_join: fu in fragment("jsonb_array_elements(?)", n.from_users),
      where: fragment("?->>'login' = ?", fu, ^from_user.login)
    )
    |> Repo.all()
    |> done
  end

  defp is_valid?(%{action: :follow} = attrs), do: attrs |> all_exist?([:user_id])

  defp is_valid?(%{action: :upvote} = attrs) do
    attrs |> all_exist?([:article_id, :thread, :title, :user_id])
  end

  defp is_valid?(%{action: :collect} = attrs) do
    attrs |> all_exist?([:article_id, :thread, :title, :user_id])
  end

  defp is_valid?(%{action: :comment} = attrs) do
    attrs |> all_exist?([:article_id, :thread, :title, :comment_id, :user_id])
  end

  defp is_valid?(%{action: :reply} = attrs) do
    attrs |> all_exist?([:article_id, :thread, :title, :comment_id, :user_id])
  end

  defp is_valid?(_), do: false

  # 确保 key 存在，并且不为 nil
  defp all_exist?(attrs, keys) when is_map(attrs) and is_list(keys) do
    Enum.all?(keys, &(Map.has_key?(attrs, &1) and not is_nil(attrs[&1])))
  end

  # 此时间段内的相似通知会被 merge
  defp interval_threshold_time() do
    Timex.shift(Timex.now(), hours: -@notify_group_interval_hour)
  end

  defp result({:ok, %{upsert_notifications: result}}), do: {:ok, result}
  defp result({:ok, %{revoke_notifications: result}}), do: {:ok, result}
  defp result({:error, _, result, _steps}), do: {:error, result}
end
