defmodule GroupherServer.CMS.Delegate.ArticleCollect do
  @moduledoc """
  reaction[upvote, collect, watch ...] on article [post, job...]
  """
  import GroupherServer.CMS.Helper.Matcher2
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, strip_struct: 1]
  # import Helper.ErrorCode
  import ShortMaps

  alias Helper.{ORM, QueryBuilder}
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{ArticleUpvote, ArticleCollect, Embeds}

  alias Ecto.Multi

  @default_article_meta Embeds.ArticleMeta.default_meta()

  @doc """
  get paged collected users
  """
  def collected_users(thread, article_id, filter) do
    load_reaction_users(ArticleCollect, thread, article_id, filter)
  end

  @doc """
  collect an article
  """
  def collect_article(thread, article_id, %User{id: user_id}) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: [author: :user]) do
      Multi.new()
      |> Multi.run(:inc_author_achieve, fn _, _ ->
        Accounts.achieve(article.author.user, :inc, :collect)
      end)
      |> Multi.run(:inc_article_collects_count, fn _, _ ->
        update_article_upvotes_count(info, article, :collects_count, :inc)
      end)
      |> Multi.run(:update_article_reaction_user_list, fn _, _ ->
        update_article_reaction_user_list(:collect, article, user_id, :add)
      end)
      |> Multi.run(:create_collect, fn _, _ ->
        thread_upcase = thread |> to_string |> String.upcase()
        args = Map.put(%{user_id: user_id, thread: thread_upcase}, info.foreign_key, article.id)

        ORM.create(ArticleCollect, args)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  # 用于在收藏时，用户添加文章到不同的收藏夹中的情况
  # 如果是同一篇文章，只创建一次，collect_article 不创建记录，只是后续设置不同的收藏夹即可
  # 如果是第一次收藏，那么才创建文章收藏记录
  # 避免因为同一篇文章在不同收藏夹内造成的统计和用户成就系统的混乱
  def collect_article_ifneed(thread, article_id, %User{id: user_id} = user) do
    with findby_args <- collection_findby_args(thread, article_id, user_id) do
      already_collected = ORM.find_by(ArticleCollect, findby_args)

      case already_collected do
        {:ok, article_collect} -> {:ok, article_collect}
        {:error, _} -> collect_article(thread, article_id, user)
      end
    end
  end

  def undo_collect_article(thread, article_id, %User{id: user_id}) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: [author: :user]) do
      Multi.new()
      |> Multi.run(:dec_author_achieve, fn _, _ ->
        Accounts.achieve(article.author.user, :dec, :collect)
      end)
      |> Multi.run(:inc_article_collects_count, fn _, _ ->
        update_article_upvotes_count(info, article, :collects_count, :dec)
      end)
      |> Multi.run(:update_article_reaction_user_list, fn _, _ ->
        update_article_reaction_user_list(:collect, article, user_id, :remove)
      end)
      |> Multi.run(:undo_collect, fn _, _ ->
        args = Map.put(%{user_id: user_id}, info.foreign_key, article.id)

        ORM.findby_delete(ArticleCollect, args)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def undo_collect_article_ifneed(thread, article_id, %User{id: user_id} = user) do
    with findby_args <- collection_findby_args(thread, article_id, user_id),
         {:ok, article_collect} = ORM.find_by(ArticleCollect, findby_args) do
      case article_collect.collect_folders |> length <= 1 do
        true -> undo_collect_article(thread, article_id, user)
        false -> {:ok, article_collect}
      end
    end
  end

  def set_collect_folder(%ArticleCollect{} = collect, folder) do
    collect_folders = (collect.collect_folders ++ [folder]) |> Enum.uniq()

    collect
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:collect_folders, collect_folders)
    |> Repo.update()
  end

  def undo_set_collect_folder(%ArticleCollect{} = collect, folder) do
    collect_folders = Enum.reject(collect.collect_folders, &(&1.id == folder.id))

    case collect_folders do
      # means collect already delete
      [] ->
        {:ok, :pass}

      _ ->
        collect
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_embed(:collect_folders, collect_folders)
        |> Repo.update()
    end
  end

  defp collection_findby_args(thread, article_id, user_id) do
    with {:ok, info} <- match(thread) do
      thread_upcase = thread |> to_string |> String.upcase()
      %{thread: thread_upcase, user_id: user_id} |> Map.put(info.foreign_key, article_id)
    end
  end

  #############
  #############
  #############

  # TODO: put in header, it's for upvotes and collect users
  defp load_reaction_users(schema, thread, article_id, %{page: page, size: size} = filter) do
    with {:ok, info} <- match(thread) do
      schema
      |> where([u], field(u, ^info.foreign_key) == ^article_id)
      |> QueryBuilder.load_inner_users(filter)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  # TODO: put in header, it's for upvotes and collect users
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

  # TODO: put in header, it's for upvotes and collect users
  @doc """
  add or remove artilce's reaction users is list history
  e.g:
  add/remove user_id to upvoted_user_ids in article meta
  """
  @spec update_article_reaction_user_list(
          :upvot | :collect,
          T.article_common(),
          String.t(),
          :add | :remove
        ) :: T.article_common()
  defp update_article_reaction_user_list(action, %{meta: nil} = article, user_id, opt) do
    cur_user_ids = []

    updated_user_ids =
      case opt do
        :add -> [user_id] ++ cur_user_ids
        :remove -> cur_user_ids -- [user_id]
      end

    meta = @default_article_meta |> Map.merge(%{"#{action}ed_user_ids": updated_user_ids})
    ORM.update_meta(article, meta)
  end

  defp update_article_reaction_user_list(action, article, user_id, opt) do
    cur_user_ids = get_in(article, [:meta, :"#{action}ed_user_ids"])

    updated_user_ids =
      case opt do
        :add -> [user_id] ++ cur_user_ids
        :remove -> cur_user_ids -- [user_id]
      end

    meta = article.meta |> Map.merge(%{"#{action}ed_user_ids": updated_user_ids}) |> strip_struct
    ORM.update_meta(article, meta)
  end

  defp result({:ok, %{create_collect: result}}), do: result |> done()
  defp result({:ok, %{undo_collect: result}}), do: result |> done()

  defp result({:error, _, result, _steps}) do
    {:error, result}
  end
end
