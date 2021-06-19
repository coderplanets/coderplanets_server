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

  @supported_notify_type get_config(:general, :nofity_types)
  @notify_group_interval_hour get_config(:general, :notify_group_interval_hour)

  def handle(%{action: action, user_id: user_id} = attrs, %User{} = from_user) do
    with true <- action in @supported_notify_type,
         true <- is_valid?(attrs),
         true <- user_id !== from_user.id do
      from_user = from_user |> Map.take([:login, :nickname]) |> Map.put(:user_id, from_user.id)

      case similar_notify_latest_peroid(attrs) do
        {:ok, notify} -> merge_notification(notify, from_user)
        {:error, _} -> create_notification(attrs, from_user)
      end
    else
      false -> {:error, "invalid args for notification"}
      error -> error
    end
  end

  def paged_notifications(user_id, %{page: page, size: size} = filter) do
    read = Map.get(filter, :read, false)

    Notification
    |> where([n], n.user_id == ^user_id)
    |> where([n], n.read == ^read)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  # 如果在临近时间段内有类似操作，直接将这次的操作人添加到 from_users 中即可
  # 避免对统一操作的大量重复消息提醒，体验不好
  defp merge_notification(notify, from_user) do
    cur_from_users = notify.from_users |> Enum.map(&strip_struct(&1))
    from_users = ([from_user] ++ cur_from_users) |> Enum.uniq()

    notify |> ORM.update_embed(:from_users, from_users)
  end

  defp create_notification(attrs, from_user) do
    %Notification{}
    |> Ecto.Changeset.change(atom_values_to_upcase(attrs))
    |> Ecto.Changeset.put_embed(:from_users, [from_user])
    |> Repo.insert()
  end

  defp similar_notify_latest_peroid(%{action: :follow} = attrs) do
    do_find_similar(Notification, attrs)
  end

  defp similar_notify_latest_peroid(%{comment_id: comment_id} = attrs)
       when not is_nil(comment_id) do
    ~m(type article_id comment_id)a = atom_values_to_upcase(attrs)

    Notification
    |> where([n], n.type == ^type and n.article_id == ^article_id and n.comment_id == ^comment_id)
    |> do_find_similar(attrs)
  end

  defp similar_notify_latest_peroid(attrs) do
    ~m(type article_id)a = atom_values_to_upcase(attrs)

    Notification
    |> where([n], n.type == ^type and n.article_id == ^article_id)
    |> do_find_similar(attrs)
  end

  defp do_find_similar(queryable, attrs) do
    ~m(user_id action)a = atom_values_to_upcase(attrs)

    queryable
    |> where([n], n.inserted_at >= ^interval_threshold_time() and n.user_id == ^user_id)
    |> where([n], n.action == ^action and n.read == false)
    |> Repo.one()
    |> done
  end

  # [:upvote, :comment, :reply, :collect, :follow]
  defp is_valid?(%{action: :upvote, type: :comment} = attrs) do
    attrs |> all_exist?([:article_id, :type, :title, :comment_id, :user_id])
  end

  defp is_valid?(%{action: :upvote} = attrs) do
    attrs |> all_exist?([:article_id, :type, :title, :user_id])
  end

  defp is_valid?(%{action: :comment} = attrs) do
    attrs |> all_exist?([:article_id, :type, :title, :comment_id, :user_id])
  end

  defp is_valid?(%{action: :reply} = attrs) do
    attrs |> all_exist?([:article_id, :type, :title, :comment_id, :user_id])
  end

  defp is_valid?(%{action: :collect} = attrs) do
    attrs |> all_exist?([:article_id, :type, :title, :user_id])
  end

  defp is_valid?(%{action: :follow} = attrs), do: attrs |> all_exist?([:user_id])

  defp is_valid?(_), do: false

  # 确保 key 存在，并且不为 nil
  defp all_exist?(attrs, keys) when is_map(attrs) and is_list(keys) do
    Enum.all?(keys, fn key ->
      Map.has_key?(attrs, key) and not is_nil(attrs[key])
    end)
  end

  # 此时间段内的相似通知会被 merge
  defp interval_threshold_time() do
    Timex.shift(Timex.now(), hours: -@notify_group_interval_hour)
  end
end
