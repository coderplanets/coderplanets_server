defmodule GroupherServer.CMS.Delegate.Hooks.Notify do
  @moduledoc """
  notify hooks, for upvote, collect, comment, reply
  """
  import Helper.Utils, only: [get_config: 2, thread_of_article: 1]
  import GroupherServer.CMS.Delegate.Helper, only: [preload_author: 1]

  alias GroupherServer.{Accounts, CMS, Delivery, Repo}

  alias Accounts.Model.User
  alias CMS.Model.Comment

  # def handle(action, %Comment{id: comment_id} = comment, %User{} = from_user) do
  # end

  def handle(:undo, action, article, %User{} = from_user) do
    {:ok, article} = preload_author(article)
    {:ok, thread} = thread_of_article(article)

    notify_attrs = %{
      type: thread,
      article_id: article.id,
      action: action,
      user_id: article.author.user.id
    }

    Delivery.revoke(:notify, notify_attrs, from_user)
  end

  def handle(action, article, %User{} = from_user) do
    {:ok, article} = preload_author(article)

    {:ok, thread} = thread_of_article(article)

    notify_attrs = %{
      type: thread,
      article_id: article.id,
      title: article.title,
      action: action,
      user_id: article.author.user.id
    }

    Delivery.send(:notify, notify_attrs, from_user)
  end
end
