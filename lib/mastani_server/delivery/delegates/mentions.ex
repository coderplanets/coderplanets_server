defmodule MastaniServer.Delivery.Delegate.Mentions do
  @moduledoc """
  The Delivery context.
  """
  import Helper.Utils, only: [stringfy: 1]
  alias MastaniServer.Repo
  alias MastaniServer.Accounts.User
  alias MastaniServer.Delivery.Mention

  alias MastaniServer.Delivery.Delegate.Utils

  # TODO: move mention logic to create contents
  # TODO: 同一篇文章不能 mention 同一个 user 多次？
  def mention_others(%User{id: _from_user_id}, [], _info), do: {:error, %{done: false}}
  def mention_others(%User{id: _from_user_id}, nil, _info), do: {:error, %{done: false}}
  def mention_others(%User{id: _from_user_id}, [nil], _info), do: {:error, %{done: false}}

  def mention_others(%User{id: from_user_id}, to_uses, info) do
    other_users = Enum.uniq(to_uses)

    records =
      Enum.reduce(other_users, [], fn to_user, acc ->
        attrs = %{
          from_user_id: from_user_id,
          to_user_id: idfy_ifneed(to_user.id),
          source_id: stringfy(info.source_id),
          source_title: info.source_title,
          source_type: info.source_type,
          source_preview: info.source_preview,
          parent_id: stringfy(Map.get(info, :parent_id)),
          parent_type: stringfy(Map.get(info, :parent_type)),
          # timestamp are not auto-gen, see:
          # https://stackoverflow.com/questions/37537094/insert-all-does-not-create-auto-generated-inserted-at-with-ecto-2-0/46844417
          # Ecto.DateTime.utc(),
          inserted_at: DateTime.truncate(Timex.now(), :second),
          # Ecto.DateTime.utc()
          updated_at: DateTime.truncate(Timex.now(), :second)
        }

        acc ++ [attrs]
      end)

    Repo.insert_all(Mention, records)

    {:ok, %{done: true}}
    # |> done(:status)
  end

  def idfy_ifneed(id) when is_binary(id), do: String.to_integer(id)
  def idfy_ifneed(id), do: id

  def mention_from_content(:post, content, args, %User{} = from_user) do
    to_user_ids = Map.get(args, :mention_users)
    topic = Map.get(args, :topic, "posts")

    info = %{
      source_title: content.title,
      source_type: topic,
      source_id: content.id,
      source_preview: content.digest
    }

    mention_others(from_user, to_user_ids, info)
  end

  def mention_from_content(_, _content, _args, %User{} = _from_user) do
    {:ok, %{done: :pass}}
  end

  def mention_from_comment(thread, content, comment, args, %User{} = from_user) do
    to_user_ids = Map.get(args, :mention_users)

    info = %{
      source_title: content.title,
      source_type: "comment",
      source_id: comment.id,
      source_preview: comment.body,
      floor: comment.floor,
      parent_id: content.id,
      parent_type: thread,
    }

    mention_others(from_user, to_user_ids, info)
  end

  @doc """
  fetch mentions from Delivery stop
  """
  def fetch_mentions(%User{} = user, %{page: _, size: _, read: _} = filter) do
    Utils.fetch_messages(user, Mention, filter)
  end
end
