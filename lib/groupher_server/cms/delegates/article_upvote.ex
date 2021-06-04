defmodule GroupherServer.CMS.Delegate.ArticleUpvote do
  @moduledoc """
  reaction[upvote, collect, watch ...] on article [post, job...]
  """
  import GroupherServer.CMS.Helper.Matcher
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]

  import GroupherServer.CMS.Delegate.Helper,
    only: [
      load_reaction_users: 4,
      update_article_reactions_count: 4,
      update_article_reaction_user_list: 4
    ]

  # import Helper.ErrorCode

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.Model.ArticleUpvote

  alias Ecto.Multi

  def upvoted_users(thread, article_id, filter) do
    load_reaction_users(ArticleUpvote, thread, article_id, filter)
  end

  @doc "upvote to a article-like content"
  def upvote_article(thread, article_id, %User{id: user_id}) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: [author: :user]) do
      Multi.new()
      |> Multi.run(:inc_article_upvotes_count, fn _, _ ->
        update_article_reactions_count(info, article, :upvotes_count, :inc)
      end)
      |> Multi.run(:update_article_reaction_user_list, fn _, _ ->
        update_article_reaction_user_list(:upvot, article, user_id, :add)
      end)
      |> Multi.run(:add_achievement, fn _, _ ->
        achiever_id = article.author.user_id
        Accounts.achieve(%User{id: achiever_id}, :inc, :upvote)
      end)
      |> Multi.run(:create_upvote, fn _, _ ->
        thread_upcase = thread |> to_string |> String.upcase()
        args = Map.put(%{user_id: user_id, thread: thread_upcase}, info.foreign_key, article.id)

        with {:ok, _} <- ORM.create(ArticleUpvote, args) do
          ORM.find(info.model, article.id)
        end
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc "upvote to a article-like content"
  def undo_upvote_article(thread, article_id, %User{id: user_id}) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:inc_article_upvotes_count, fn _, _ ->
        update_article_reactions_count(info, article, :upvotes_count, :dec)
      end)
      |> Multi.run(:update_article_reaction_user_list, fn _, _ ->
        update_article_reaction_user_list(:upvot, article, user_id, :remove)
      end)
      |> Multi.run(:undo_upvote, fn _, _ ->
        args = Map.put(%{user_id: user_id}, info.foreign_key, article.id)

        ORM.findby_delete(ArticleUpvote, args)
        ORM.find(info.model, article.id)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  defp result({:ok, %{create_upvote: result}}), do: result |> done()
  defp result({:ok, %{undo_upvote: result}}), do: result |> done()
  defp result({:error, _, result, _steps}), do: {:error, result}
end
