defmodule GroupherServer.CMS.Delegate.ArticleUpvote do
  @moduledoc """
  reaction[upvote, collect, watch ...] on article [post, job...]
  """
  import GroupherServer.CMS.Helper.Matcher
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import Helper.ErrorCode

  import GroupherServer.CMS.Delegate.Helper,
    only: [
      load_reaction_users: 4,
      update_article_reactions_count: 4,
      update_article_reaction_user_list: 4
    ]

  # import Helper.ErrorCode

  alias Helper.{ORM, Later}
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.Model.User
  alias CMS.Model.ArticleUpvote
  alias CMS.Delegate.Hooks

  alias Ecto.Multi

  def upvoted_users(thread, article_id, filter) do
    load_reaction_users(ArticleUpvote, thread, article_id, filter)
  end

  @doc "upvote to a article-like content"
  def upvote_article(thread, article_id, %User{id: user_id} = from_user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: [author: :user]) do
      Multi.new()
      |> Multi.run(:update_upvotes_count, fn _, _ ->
        update_article_reactions_count(info, article, :upvotes_count, :inc)
      end)
      |> Multi.run(:update_reaction_user_list, fn _, %{update_upvotes_count: article} ->
        update_article_reaction_user_list(:upvot, article, from_user, :add)
      end)
      |> Multi.run(:add_achievement, fn _, _ ->
        achiever_id = article.author.user_id
        Accounts.achieve(%User{id: achiever_id}, :inc, :upvote)
      end)
      |> Multi.run(:create_upvote, fn _, %{update_reaction_user_list: article} ->
        thread = thread |> to_string |> String.upcase()
        args = Map.put(%{user_id: user_id, thread: thread}, info.foreign_key, article.id)

        with {:ok, _} <- ORM.create(ArticleUpvote, args) do
          article |> done
        else
          _ -> {:error, [message: "viewer already upvoted", code: ecode(:already_upvoted)]}
        end
      end)
      |> Multi.run(:after_hooks, fn _, _ ->
        Later.run({Hooks.Notify, :handle, [:upvote, article, from_user]})
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc "upvote to a article-like content"
  def undo_upvote_article(thread, article_id, %User{id: user_id} = from_user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:update_upvotes_count, fn _, _ ->
        update_article_reactions_count(info, article, :upvotes_count, :dec)
      end)
      |> Multi.run(:update_reaction_user_list, fn _, %{update_upvotes_count: article} ->
        update_article_reaction_user_list(:upvot, article, from_user, :remove)
      end)
      |> Multi.run(:undo_upvote, fn _, %{update_reaction_user_list: article} ->
        args = Map.put(%{user_id: user_id}, info.foreign_key, article.id)

        ORM.findby_delete(ArticleUpvote, args)
        article |> done
      end)
      |> Multi.run(:after_hooks, fn _, _ ->
        Later.run({Hooks.Notify, :handle, [:undo, :upvote, article, from_user]})
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  defp result({:ok, %{create_upvote: result}}), do: result |> done()
  defp result({:ok, %{undo_upvote: result}}), do: result |> done()
  defp result({:error, _, result, _steps}), do: {:error, result}
end
