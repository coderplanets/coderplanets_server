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
  }
  """

  def batch_mention(%Comment{} = comment, contents, %User{} = user, %User{} = to_user) do
    Multi.new()
    |> Multi.run(:batch_delete_related_mentions, fn _, _ ->
      delete_related_mentions(comment, user)
    end)
    |> Multi.run(:batch_insert_related_mentions, fn _, _ ->
      case {0, nil} !== Repo.insert_all(Mention, contents) do
        true -> {:ok, :pass}
        false -> {:error, "insert mentions error"}
      end
    end)
    |> Repo.transaction()
    |> result()

    # 1.
    # delete_all Mention |> where from_user_id == user.id and comment_id == comment.id
    # 2.
    # insert_all shaped contents
  end

  def batch_mention(article, contents, %User{} = user, %User{} = to_user) do
    Multi.new()
    |> Multi.run(:batch_delete_related_mentions, fn _, _ ->
      delete_related_mentions(article, user)
    end)
    |> Multi.run(:batch_insert_related_mentions, fn _, _ ->
      case {0, nil} !== Repo.insert_all(Mention, contents) do
        true -> {:ok, :pass}
        false -> {:error, "insert mentions error"}
      end
    end)
    |> Repo.transaction()
    |> result()
  end

  defp result({:ok, %{batch_insert_related_mentions: result}}), do: {:ok, result}

  defp result({:error, _, result, _steps}) do
    {:error, result}
  end

  defp delete_related_mentions(%Comment{} = comment, %User{} = user) do
    from(m in Mention,
      where: m.comment_id == ^comment.id,
      where: m.from_user_id == ^user.id
    )
    |> ORM.delete_all(:if_exist)
  end

  defp delete_related_mentions(article, %User{} = user) do
    with {:ok, thread} <- thread_of_article(article),
         {:ok, info} <- match(thread) do
      thread = thread |> to_string |> String.upcase()

      from(m in Mention,
        where: m.article_id == ^article.id,
        where: m.type == ^thread,
        where: m.from_user_id == ^user.id
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
    |> done()
  end

  @doc """
  fetch mentions from Delivery stop
  """
  def fetch_mentions(%User{} = user, %{page: _, size: _, read: _} = filter) do
    Utils.fetch_messages(user, OldMention, filter)
  end
end
