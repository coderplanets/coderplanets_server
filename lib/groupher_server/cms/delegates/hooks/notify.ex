defmodule GroupherServer.CMS.Delegate.Hooks.Notify do
  @moduledoc """
  notify hooks, for upvote, collect, comment, reply
  """
  import Helper.Utils, only: [thread_of_article: 1]
  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{Accounts, CMS, Delivery, Repo}

  alias Accounts.Model.User
  alias CMS.Model.Comment

  def handle(:undo, action, %Comment{} = comment, %User{} = from_user) do
    article_thread = comment.thread |> String.downcase() |> String.to_atom()
    article = comment |> Repo.preload(article_thread) |> Map.get(article_thread)

    notify_attrs = %{
      action: action,
      type: :comment,
      article_id: article.id,
      title: article.title,
      comment_id: comment.id,
      user_id: comment.author_id
    }

    Delivery.revoke(:notify, notify_attrs, from_user)
  end

  def handle(:undo, action, article, %User{} = from_user) do
    {:ok, article} = preload_author(article)
    {:ok, thread} = thread_of_article(article)

    notify_attrs = %{
      action: action,
      type: thread,
      article_id: article.id,
      user_id: article.author.user.id
    }

    Delivery.revoke(:notify, notify_attrs, from_user)
  end

  def handle(action, %Comment{} = comment, %User{} = from_user) do
    article_thread = comment.thread |> String.downcase() |> String.to_atom()
    article = comment |> Repo.preload(article_thread) |> Map.get(article_thread)

    notify_attrs = %{
      action: action,
      type: :comment,
      article_id: article.id,
      title: article.title,
      comment_id: comment.id,
      user_id: comment.author_id
    }

    Delivery.send(:notify, notify_attrs, from_user)
  end

  def handle(action, article, %User{} = from_user) do
    {:ok, article} = preload_author(article)
    {:ok, thread} = thread_of_article(article)

    notify_attrs = %{
      action: action,
      type: thread,
      article_id: article.id,
      title: article.title,
      user_id: article.author.user.id
    }

    Delivery.send(:notify, notify_attrs, from_user)
  end
end
