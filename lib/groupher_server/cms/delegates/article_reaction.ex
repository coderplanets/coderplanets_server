defmodule GroupherServer.CMS.Delegate.ArticleReaction do
  @moduledoc """
  reaction[favorite, star, watch ...] on article [post, job...]
  """
  import Helper.Utils, only: [done: 1, done: 2]

  import GroupherServer.CMS.Utils.Matcher2
  import GroupherServer.CMS.Utils.Matcher, only: [match_action: 2]
  import Ecto.Query, warn: false
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.{ORM, QueryBuilder}
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{ArticleUpvote, ArticleCollect}

  alias Ecto.Multi

  def upvoted_users(thread, article_id, filter) do
    load_reaction_users(ArticleUpvote, thread, article_id, filter)
  end

  def collected_users(thread, article_id, filter) do
    load_reaction_users(ArticleCollect, thread, article_id, filter)
  end

  defp load_reaction_users(schema, thread, article_id, %{page: page, size: size} = filter) do
    with {:ok, info} <- match(thread) do
      schema
      |> where([u], field(u, ^info.foreign_key) == ^article_id)
      |> QueryBuilder.load_inner_users(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  def collect_article(thread, article_id, %User{id: user_id}) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:inc_article_collects_count, fn _, _ ->
        update_article_upvotes_count(info, article, :collects_count, :inc)
      end)
      |> Multi.run(:create_collect, fn _, _ ->
        thread_upcase = thread |> to_string |> String.upcase()
        args = Map.put(%{user_id: user_id, thread: thread_upcase}, info.foreign_key, article.id)

        ORM.create(ArticleCollect, args)
      end)
      |> Repo.transaction()
      |> reaction_result()
    end
  end

  def undo_collect_article(thread, article_id, %User{id: user_id}) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:inc_article_collects_count, fn _, _ ->
        update_article_upvotes_count(info, article, :collects_count, :dec)
      end)
      |> Multi.run(:undo_collect, fn _, _ ->
        args = Map.put(%{user_id: user_id}, info.foreign_key, article.id)

        ORM.findby_delete(ArticleCollect, args)
        ORM.find(info.model, article.id)
      end)
      |> Repo.transaction()
      |> reaction_result()
    end
  end

  @doc "upvote to a article-like content"
  def upvote_article(thread, article_id, %User{id: user_id}) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:inc_article_upvotes_count, fn _, _ ->
        update_article_upvotes_count(info, article, :upvotes_count, :inc)
      end)
      |> Multi.run(:create_upvote, fn _, _ ->
        thread_upcase = thread |> to_string |> String.upcase()
        args = Map.put(%{user_id: user_id, thread: thread_upcase}, info.foreign_key, article.id)

        with {:ok, _} <- ORM.create(ArticleUpvote, args) do
          ORM.find(info.model, article.id)
        end
      end)
      |> Repo.transaction()
      |> reaction_result()
    end
  end

  @doc "upvote to a article-like content"
  def undo_upvote_article(thread, article_id, %User{id: user_id}) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:inc_article_upvotes_count, fn _, _ ->
        update_article_upvotes_count(info, article, :upvotes_count, :dec)
      end)
      |> Multi.run(:undo_upvote, fn _, _ ->
        args = Map.put(%{user_id: user_id}, info.foreign_key, article.id)

        ORM.findby_delete(ArticleUpvote, args)
        ORM.find(info.model, article.id)
      end)
      |> Repo.transaction()
      |> reaction_result()
    end
  end

  defp update_article_upvotes_count(info, article, field, opt) do
    schema =
      case field do
        :upvotes_count -> ArticleUpvote
        :collects_count -> ArticleCollect
      end

    count_query = from(u in schema, where: field(u, ^info.foreign_key) == ^article.id)
    cur_count = Repo.aggregate(count_query, :count)

    case opt do
      :inc ->
        new_count = Enum.max([0, cur_count])
        ORM.update(article, Map.put(%{}, field, new_count + 1))

      :dec ->
        new_count = Enum.max([1, cur_count])
        ORM.update(article, Map.put(%{}, field, new_count - 1))
    end
  end

  defp reaction_result({:ok, %{create_upvote: result}}), do: result |> done()
  defp reaction_result({:ok, %{undo_upvote: result}}), do: result |> done()

  defp reaction_result({:ok, %{create_collect: result}}), do: result |> done()
  defp reaction_result({:ok, %{undo_collect: result}}), do: result |> done()

  defp reaction_result({:error, _, result, _steps}) do
    {:error, result}
  end

  @doc """
  favorite / star / watch CMS contents like post / tuts ...
  """
  def reaction(thread, react, content_id, %User{id: user_id}) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, content} <- ORM.find(action.target, content_id, preload: [author: :user]),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      Multi.new()
      |> Multi.run(:create_reaction_record, fn _, _ ->
        create_reaction_record(action, user, thread, content)
      end)
      |> Multi.run(:add_achievement, fn _, _ ->
        achiever_id = content.author.user_id
        Accounts.achieve(%User{id: achiever_id}, :add, react)
      end)
      |> Repo.transaction()
      |> old_reaction_result()
    end
  end

  defp old_reaction_result({:ok, %{create_reaction_record: result}}), do: result |> done()

  defp old_reaction_result({:error, :create_reaction_record, %Ecto.Changeset{} = result, _steps}) do
    {:error, result}
  end

  defp old_reaction_result({:error, :create_reaction_record, _result, _steps}) do
    {:error, [message: "create reaction fails", code: ecode(:react_fails)]}
  end

  defp old_reaction_result({:error, :add_achievement, _result, _steps}),
    do: {:error, [message: "achieve fails", code: ecode(:react_fails)]}

  defp create_reaction_record(action, %User{id: user_id}, thread, content) do
    attrs = %{} |> Map.put("user_id", user_id) |> Map.put("#{thread}_id", content.id)

    action.reactor
    |> ORM.create(attrs)
    |> done(with: content)
  end

  # ------
  @doc """
  unfavorite / unstar / unwatch CMS contents like post / tuts ...
  """
  def undo_reaction(thread, react, content_id, %User{id: user_id}) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, content} <- ORM.find(action.target, content_id, preload: [author: :user]),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      Multi.new()
      |> Multi.run(:delete_reaction_record, fn _, _ ->
        delete_reaction_record(action, user, thread, content)
      end)
      |> Multi.run(:minus_achievement, fn _, _ ->
        achiever_id = content.author.user_id
        Accounts.achieve(%User{id: achiever_id}, :minus, react)
      end)
      |> Repo.transaction()
      |> undo_reaction_result()
    end
  end

  defp undo_reaction_result({:ok, %{delete_reaction_record: result}}), do: result |> done()

  defp undo_reaction_result({:error, :delete_reaction_record, _result, _steps}) do
    {:error, [message: "delete reaction fails", code: ecode(:react_fails)]}
  end

  defp undo_reaction_result({:error, :minus_achievement, _result, _steps}),
    do: {:error, [message: "achieve fails", code: ecode(:react_fails)]}

  defp delete_reaction_record(action, %User{id: user_id}, thread, content) do
    user_where = dynamic([u], u.user_id == ^user_id)
    reaction_where = dynamic_reaction_where(thread, content.id, user_where)

    query = from(f in action.reactor, where: ^reaction_where)

    case Repo.one(query) do
      nil ->
        {:error, "record not found"}

      record ->
        Repo.delete(record)
        {:ok, content}
    end
  end

  defp dynamic_reaction_where(:post, id, user_where) do
    dynamic([p], p.post_id == ^id and ^user_where)
  end

  defp dynamic_reaction_where(:job, id, user_where) do
    dynamic([p], p.job_id == ^id and ^user_where)
  end

  defp dynamic_reaction_where(:repo, id, user_where) do
    dynamic([p], p.repo_id == ^id and ^user_where)
  end
end
