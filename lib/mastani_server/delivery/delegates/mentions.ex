defmodule MastaniServer.Delivery.Delegate.Mentions do
  @moduledoc """
  The Delivery context.
  """
  import Helper.Utils, only: [done: 2]

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.User
  alias MastaniServer.Delivery.Mention
  alias Helper.ORM

  alias MastaniServer.Delivery.Delegate.Utils

  # TODO: move mention logic to create contents
  # TODO: 同一篇文章不能 mention 同一个 user 多次？
  def mention_others(%User{id: from_user_id}, to_user_ids, info) do
    other_user_ids = Enum.uniq(to_user_ids) |> Enum.map(&idfy_ifneed/1)

    records =
      Enum.reduce(other_user_ids, [], fn to_user_id, acc ->
        attrs = %{
          from_user_id: from_user_id,
          to_user_id: to_user_id,
          source_id: info.source_id,
          source_title: info.source_title,
          source_type: info.source_type,
          source_preview: info.source_preview,
          # timestamp are not auto-gen, see:
          # https://stackoverflow.com/questions/37537094/insert-all-does-not-create-auto-generated-inserted-at-with-ecto-2-0/46844417
          inserted_at: Ecto.DateTime.utc(),
          updated_at: Ecto.DateTime.utc()
        }

        acc ++ [attrs]
      end)

    Repo.insert_all(Mention, records)

    {:ok, %{done: true}}
    # |> done(:status)
  end

  def idfy_ifneed(id) when is_binary(id), do: String.to_integer(id)
  def idfy_ifneed(id), do: id

  @doc """
  fetch mentions from Delivery stop
  """
  def fetch_mentions(%User{} = user, %{page: _, size: _, read: _} = filter) do
    Utils.fetch_messages(user, Mention, filter)
  end
end
