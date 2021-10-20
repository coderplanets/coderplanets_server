defmodule GroupherServer.CMS.Delegate.Hooks.Notify do
  @moduledoc """
  notify hooks, for upvote, collect, comment, reply
  """
  import GroupherServer.CMS.Delegate.Helper,
    only: [preload_author: 1, article_of: 1, thread_of: 1]

  alias GroupherServer.{Accounts, CMS, Delivery, Repo}

  alias Accounts.Model.User
  alias CMS.Model.Comment

  # 发布评论是特殊情况，单独处理
  def handle(:comment, %Comment{} = comment, %User{} = from_user) do
    {:ok, article} = article_of(comment)
    {:ok, article} = preload_author(article)
    {:ok, thread} = thread_of(article)

    notify_attrs = %{
      action: :comment,
      thread: thread,
      article_id: article.id,
      title: article.title,
      comment_id: comment.id,
      # NOTE: 这里是提醒该评论文章的作者，不是评论本身的作者
      user_id: article.author.user.id
    }

    Delivery.send(:notify, notify_attrs, from_user)
  end

  # 回复评论是特殊情况，单独处理
  def handle(:reply, %Comment{} = reply_comment, %User{} = from_user) do
    reply_comment = Repo.preload(reply_comment, reply_to: :author)

    {:ok, article} = article_of(reply_comment)
    {:ok, article} = preload_author(article)
    {:ok, thread} = thread_of(article)

    notify_attrs = %{
      action: :reply,
      thread: thread,
      article_id: article.id,
      title: article.title,
      comment_id: reply_comment.id,
      # NOTE: 这里是提醒该评论的作者，不提醒文章作者了
      user_id: reply_comment.reply_to.author_id
    }

    Delivery.send(:notify, notify_attrs, from_user)
  end

  def handle(action, %Comment{} = comment, %User{} = from_user) do
    {:ok, article} = article_of(comment)
    {:ok, thread} = thread_of(article)

    notify_attrs = %{
      action: action,
      thread: thread,
      article_id: article.id,
      title: article.title,
      user_id: comment.author_id,
      comment_id: comment.id
    }

    Delivery.send(:notify, notify_attrs, from_user)
  end

  def handle(action, article, %User{} = from_user) do
    {:ok, article} = preload_author(article)
    {:ok, thread} = thread_of(article)

    notify_attrs = %{
      action: action,
      thread: thread,
      article_id: article.id,
      title: article.title,
      user_id: article.author.user.id
    }

    Delivery.send(:notify, notify_attrs, from_user)
  end

  def handle(:undo, action, %Comment{} = comment, %User{} = from_user) do
    {:ok, article} = article_of(comment)
    {:ok, thread} = thread_of(article)

    notify_attrs = %{
      action: action,
      thread: thread,
      article_id: article.id,
      title: article.title,
      comment_id: comment.id,
      user_id: comment.author_id
    }

    Delivery.revoke(:notify, notify_attrs, from_user)
  end

  def handle(:undo, action, article, %User{} = from_user) do
    {:ok, article} = preload_author(article)
    {:ok, thread} = thread_of(article)

    notify_attrs = %{
      action: action,
      thread: thread,
      article_id: article.id,
      user_id: article.author.user.id
    }

    Delivery.revoke(:notify, notify_attrs, from_user)
  end
end
