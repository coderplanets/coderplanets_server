defmodule GroupherServer.CMS.Delegate.Hooks.Mention do
  @moduledoc """
  hooks for mention task

  parse and fmt(see shape function) mentions to Delivery module
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [get_config: 2]

  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1, author_of: 1, thread_of: 1]
  import GroupherServer.CMS.Delegate.Hooks.Helper, only: [merge_same_block_linker: 2]

  alias GroupherServer.{Accounts, CMS, Delivery, Repo}
  alias CMS.Model.Comment

  @article_threads get_config(:article, :threads)

  @article_mention_class "cdx-mention"

  def handle(%{body: body} = artiment) when not is_nil(body) do
    with {:ok, %{"blocks" => blocks}} <- Jason.decode(body),
         {:ok, artiment} <- preload_author(artiment) do
      blocks
      |> Enum.reduce([], &(&2 ++ parse_mention_info_per_block(artiment, &1)))
      |> merge_same_block_linker(:to_user_id)
      |> handle_mentions(artiment)
    end
  end

  def handle(%{document: _document} = article) do
    body = Repo.preload(article, :document) |> get_in([:document, :body])
    article = article |> Map.put(:body, body)
    handle(article)
  end

  defp handle_mentions(mentions, artiment) do
    with {:ok, author} <- author_of(artiment) do
      Delivery.send(:mention, artiment, mentions, author)
    end
  end

  defp parse_mention_info_per_block(artiment, %{"id" => block_id, "data" => %{"text" => text}}) do
    mentions = Floki.find(text, ".#{@article_mention_class}")

    parse_mention_in_block(artiment, block_id, mentions)
  end

  # mentions Floki parsed fmt
  # artiment means both article and comment
  # e.g:
  # [{"div", [{"class", "cdx-mention"}], ["penelope438"]}]
  defp parse_mention_in_block(artiment, block_id, mentions) do
    Enum.reduce(mentions, [], fn mention, acc ->
      case parse_mention_user_id(artiment, mention) do
        {:ok, user_id} -> List.insert_at(acc, 0, shape(artiment, user_id, block_id))
        {:error, _} -> acc
      end
    end)
    |> Enum.uniq()
  end

  # make sure mention user is exsit and not author self
  # 确保 mention 的用户是存在的, 并且不是在提及自己
  defp parse_mention_user_id(artiment, {_, _, [user_login]}) do
    with {:ok, author} <- author_of(artiment),
         {:ok, user_id} <- Accounts.get_userid_and_cache(user_login) do
      case author.id !== user_id do
        true -> {:ok, user_id}
        false -> {:error, "mention yourself, ignored"}
      end
    end
  end

  defp shape(%Comment{} = comment, mention_user_id, block_id) do
    article_thread = @article_threads |> Enum.find(&(not is_nil(Map.get(comment, :"#{&1}_id"))))
    comment = Repo.preload(comment, article_thread)
    parent_article = comment |> Map.get(article_thread)

    %{
      thread: article_thread,
      title: parent_article.title,
      article_id: parent_article.id,
      comment_id: comment.id,
      block_linker: [block_id],
      read: false,
      from_user_id: comment.author_id,
      to_user_id: mention_user_id,
      inserted_at: comment.updated_at |> DateTime.truncate(:second),
      updated_at: comment.updated_at |> DateTime.truncate(:second)
    }
  end

  defp shape(article, to_user_id, block_id) do
    {:ok, thread} = thread_of(article)

    %{
      thread: thread,
      title: article.title,
      article_id: article.id,
      block_linker: [block_id],
      read: false,
      from_user_id: article.author.user_id,
      to_user_id: to_user_id,
      inserted_at: article.updated_at |> DateTime.truncate(:second),
      updated_at: article.updated_at |> DateTime.truncate(:second)
    }
  end
end
