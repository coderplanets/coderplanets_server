defmodule GroupherServer.Delivery.Delegate.Mention do
  @moduledoc """
  The Delivery context.
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, thread_of_article: 1]
  import GroupherServer.CMS.Helper.Matcher
  import ShortMaps

  alias GroupherServer.{Accounts, CMS, Delivery, Repo}

  alias Accounts.Model.User
  alias CMS.Model.Comment
  alias Delivery.Model.{OldMention, Mention}

  alias Delivery.Delegate.Utils
  alias Helper.ORM

  alias Ecto.Multi

  """
  %{
    type: "POST", # "COMMENT",
    title: "article title",
    id: 23,
    block_linker: ["die"],
    comment_id: 22,
    read: false
    from_user_id: ...
    to_user_id: ...
  }
  """

  def batch_mention(%Comment{} = comment, contents, %User{} = from_user) do
    Multi.new()
    |> Multi.run(:batch_delete_mentions, fn _, _ ->
      batch_delete_mentions(comment, from_user)
    end)
    |> Multi.run(:batch_insert_mentions, fn _, _ ->
      case {0, nil} !== Repo.insert_all(Mention, contents) do
        true -> {:ok, :pass}
        false -> {:error, "insert mentions error"}
      end
    end)
    |> Repo.transaction()
    |> result()
  end

  def batch_mention(article, contents, %User{} = from_user) do
    Multi.new()
    |> Multi.run(:batch_delete_mentions, fn _, _ ->
      batch_delete_mentions(article, from_user)
    end)
    |> Multi.run(:batch_insert_mentions, fn _, _ ->
      case {0, nil} !== Repo.insert_all(Mention, contents) do
        true -> {:ok, :pass}
        false -> {:error, "insert mentions error"}
      end
    end)
    |> Repo.transaction()
    |> result()
  end

  defp batch_delete_mentions(%Comment{} = comment, %User{} = from_user) do
    from(m in Mention,
      where: m.comment_id == ^comment.id,
      where: m.from_user_id == ^from_user.id
    )
    |> ORM.delete_all(:if_exist)
  end

  defp batch_delete_mentions(article, %User{} = from_user) do
    with {:ok, thread} <- thread_of_article(article),
         {:ok, info} <- match(thread) do
      thread = thread |> to_string |> String.upcase()

      from(m in Mention,
        where: m.article_id == ^article.id,
        where: m.type == ^thread,
        where: m.from_user_id == ^from_user.id
      )
      |> ORM.delete_all(:if_exist)
    end
  end

  def paged_mentions(%User{} = user, %{page: page, size: size} = filter) do
    read = Map.get(filter, :read, false)

    Mention
    |> where([m], m.to_user_id == ^user.id)
    |> where([m], m.read == ^read)
    |> ORM.paginater(~m(page size)a)
    |> extract_contents
    |> done()
  end

  defp extract_contents(%{entries: entries} = paged_contents) do
    entries = entries |> Repo.preload(:from_user) |> Enum.map(&shape(&1))

    Map.put(paged_contents, :entries, entries)
  end

  # who in what part, mentioned me?
  defp shape(%Mention{} = mention) do
    user = Map.take(mention.from_user, [:login, :nickname, :avatar])

    mention
    |> Map.take([
      :type,
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
