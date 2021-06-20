defmodule GroupherServer.Delivery.Delegate.Mention do
  @moduledoc """
  The Delivery context.
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, thread_of_article: 2, atom_values_to_upcase: 1]
  import ShortMaps

  alias GroupherServer.{Accounts, CMS, Delivery, Repo}

  alias Accounts.Model.User
  alias CMS.Model.Comment
  alias Delivery.Model.Mention

  alias Helper.ORM
  alias Ecto.Multi

  # 发送
  # Delivery.send(:mention, content, mentions, user)
  # Delivery.send(:notify, content, mentions, user)

  # 用户侧取
  # Delivery.fetch(:mention)

  def handle(_, [], _), do: {:ok, :pass}

  def handle(%Comment{} = comment, mentions, %User{} = from_user) do
    Multi.new()
    |> Multi.run(:batch_delete_mentions, fn _, _ ->
      batch_delete_mentions(comment, from_user)
    end)
    |> Multi.run(:batch_insert_mentions, fn _, _ ->
      case {0, nil} !== Repo.insert_all(Mention, atom_values_to_upcase(mentions)) do
        true -> {:ok, :pass}
        false -> {:error, "insert mentions error"}
      end
    end)
    |> Repo.transaction()
    |> result()
  end

  def handle(article, mentions, %User{} = from_user) do
    Multi.new()
    |> Multi.run(:batch_delete_mentions, fn _, _ ->
      batch_delete_mentions(article, from_user)
    end)
    |> Multi.run(:batch_insert_mentions, fn _, _ ->
      case {0, nil} !== Repo.insert_all(Mention, atom_values_to_upcase(mentions)) do
        true -> {:ok, :pass}
        false -> {:error, "insert mentions error"}
      end
    end)
    |> Repo.transaction()
    |> result()
  end

  def paged_mentions(%User{} = user, %{page: page, size: size} = filter) do
    read = Map.get(filter, :read, false)

    Mention
    |> where([m], m.to_user_id == ^user.id)
    |> where([m], m.read == ^read)
    |> ORM.paginater(~m(page size)a)
    |> extract_mentions
    |> done()
  end

  defp batch_delete_mentions(%Comment{} = comment, %User{} = from_user) do
    from(m in Mention,
      where: m.comment_id == ^comment.id,
      where: m.from_user_id == ^from_user.id
    )
    |> ORM.delete_all(:if_exist)
  end

  defp batch_delete_mentions(article, %User{} = from_user) do
    with {:ok, thread} <- thread_of_article(article, :upcase) do
      from(m in Mention,
        where: m.article_id == ^article.id,
        where: m.thread == ^thread,
        where: m.from_user_id == ^from_user.id
      )
      |> ORM.delete_all(:if_exist)
    end
  end

  defp extract_mentions(%{entries: entries} = paged_mentions) do
    entries = entries |> Repo.preload(:from_user) |> Enum.map(&shape(&1))

    Map.put(paged_mentions, :entries, entries)
  end

  # who in what part, mentioned me?
  defp shape(%Mention{} = mention) do
    user = Map.take(mention.from_user, [:login, :nickname, :avatar])

    mention
    |> Map.take([
      :thread,
      :article_id,
      :comment_id,
      :title,
      :block_linker,
      :inserted_at,
      :updated_at,
      :read
    ])
    |> Map.put(:user, user)
  end

  defp result({:ok, %{batch_insert_mentions: result}}), do: {:ok, result}

  defp result({:error, _, result, _steps}) do
    {:error, result}
  end
end
