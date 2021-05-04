defmodule GroupherServer.Accounts.Delegate.CollectFolder do
  @moduledoc """
  user FavoriteCategory related
  """
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Utils.Matcher2

  alias Helper.Types, as: T
  alias Helper.QueryBuilder

  import Helper.ErrorCode
  import Helper.Utils, only: [done: 1]

  import ShortMaps

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.{CollectFolder, Embeds, User}
  alias CMS.{ArticleCollect}

  alias Ecto.Multi

  # @max_article_count_per_collect_folder 300

  @default_meta Embeds.CollectFolderMeta.default_meta()
  @supported_collect_threads [:post, :job]

  @doc """
  list a user's not-private collect folders
  """
  def list_collect_folders(user_id, filter) do
    query = CollectFolder |> where([c], c.user_id == ^user_id and not c.private)

    do_list_collect_folders(filter, query)
  end

  @doc """
  list a owner's collect folders
  """
  def list_collect_folders(user_id, filter, %User{id: cur_user_id}) do
    query =
      if cur_user_id == user_id,
        do: CollectFolder |> where([c], c.user_id == ^user_id),
        else: CollectFolder |> where([c], c.user_id == ^user_id and not c.private)

    do_list_collect_folders(filter, query)
  end

  @doc """
  list article inside a collect folder
  """
  def list_collect_folder_articles(folder_id, filter) do
    with {:ok, folder} <- ORM.find(CollectFolder, folder_id) do
      case folder.private do
        true -> raise_error(:private_collect_folder, "#{folder.title} is private")
        false -> do_list_collect_folder_articles(folder, filter)
      end
    end
  end

  def list_collect_folder_articles(folder_id, filter, %User{id: cur_user_id}) do
    with {:ok, folder} <- ORM.find(CollectFolder, folder_id) do
      is_valid_request =
        case folder.private do
          true -> folder.user_id == cur_user_id
          false -> true
        end

      case is_valid_request do
        false -> raise_error(:private_collect_folder, "#{folder.title} is private")
        true -> do_list_collect_folder_articles(folder, filter)
      end
    end
  end

  defp do_list_collect_folder_articles(folder, filter) do
    Repo.preload(folder.collects, @supported_collect_threads)
    |> ORM.embeds_paginater(filter)
    |> ORM.extract_articles(@supported_collect_threads)
    |> done()
  end

  @doc """
  create a collect folder for articles
  """
  def create_collect_folder(%{title: title} = attrs, %User{id: user_id}) do
    with {:error, _} <- ORM.find_by(CollectFolder, ~m(user_id title)a) do
      last_updated = Timex.today() |> Timex.to_datetime()

      args =
        Map.merge(
          %{
            user_id: user_id,
            last_updated: last_updated,
            meta: @default_meta
          },
          attrs
        )

      CollectFolder |> ORM.create(args)
    else
      {:ok, folder} -> raise_error(:already_exsit, "#{folder.title} already exsits")
    end
  end

  def update_collect_folder(%{id: id} = attrs, %User{id: user_id}) do
    with {:ok, folder} <- ORM.find_by(CollectFolder, ~m(id user_id)a) do
      last_updated = Timex.today() |> Timex.to_datetime()
      folder |> ORM.update(Map.merge(~m(last_updated)a, attrs))
    end
  end

  @doc """
  delete empty collect folder
  """
  @spec delete_collect_folder(T.id()) :: {:ok, CollectFolder.t()}
  def delete_collect_folder(id) do
    with {:ok, folder} <- ORM.find(CollectFolder, id) do
      is_folder_empty = Enum.empty?(folder.collects)

      case is_folder_empty do
        true -> CollectFolder |> ORM.find_delete!(id)
        false -> raise_error(:delete_no_empty_collect_folder, "#{folder.title} is not empty")
      end
    end
  end

  @doc """
  add article from collect folder
  """
  @spec add_to_collect(T.article_thread(), T.id(), T.id(), User.t()) :: {:ok, CollectFolder.t()}
  def add_to_collect(thread, article_id, folder_id, %User{id: cur_user_id} = user) do
    with {:ok, folder} <- ORM.find(CollectFolder, folder_id),
         {:ok, _} <- article_not_collect_in_folder(thread, article_id, folder.collects),
         # 是否是该 folder 的 owner ?
         true <- cur_user_id == folder.user_id do
      Multi.new()
      |> Multi.run(:add_article_collect, fn _, _ ->
        CMS.collect_article_ifneed(thread, article_id, user)
      end)
      |> Multi.run(:set_article_collect_folder, fn _, %{add_article_collect: article_collect} ->
        CMS.set_collect_folder(article_collect, folder)
      end)
      |> Multi.run(:add_to_collect_folder, fn _, %{add_article_collect: article_collect} ->
        collects = [article_collect] ++ folder.collects
        update_folder_meta(thread, collects, folder)
      end)
      |> Repo.transaction()
      |> upsert_collect_folder_result()
    end
  end

  @doc """
  remove article from collect folder
  """
  @spec remove_from_collect(T.article_thread(), T.id(), T.id(), User.t()) ::
          {:ok, CollectFolder.t()}
  def remove_from_collect(thread, article_id, folder_id, %User{id: cur_user_id} = user) do
    with {:ok, folder} <- ORM.find(CollectFolder, folder_id),
         # 是否是该 folder 的 owner ?
         true <- cur_user_id == folder.user_id do
      Multi.new()
      |> Multi.run(:del_article_collect, fn _, _ ->
        CMS.undo_collect_article_ifneed(thread, article_id, user)
      end)
      |> Multi.run(:unset_article_collect_folder, fn _, %{del_article_collect: article_collect} ->
        CMS.undo_set_collect_folder(article_collect, folder)
      end)
      |> Multi.run(:rm_from_collect_folder, fn _, %{del_article_collect: article_collect} ->
        # 不能用 -- 语法，因为两个结构体的 meta 信息不同，摔。
        collects = Enum.reject(folder.collects, &(&1.id == article_collect.id))
        update_folder_meta(thread, collects, folder)
      end)
      |> Repo.transaction()
      |> upsert_collect_folder_result()
    end
  end

  @spec update_folder_meta(T.article_thread(), [ArticleCollect.t()], CollectFolder.t()) ::
          CollectFolder.t()
  defp update_folder_meta(thread, collects, folder) do
    total_count = length(collects)
    last_updated = Timex.today() |> Timex.to_datetime()

    thread_count = Enum.filter(collects, &(not is_nil(Map.get(&1, :"#{thread}_id")))) |> length

    threads_flag_map = %{"has_#{thread}": thread_count > 0}
    thread_count_map = %{"#{thread}_count": thread_count}

    meta =
      folder.meta
      |> Map.merge(threads_flag_map)
      |> Map.merge(thread_count_map)
      |> Map.from_struct()
      |> Map.delete(:id)

    folder
    |> Ecto.Changeset.change(%{total_count: total_count, last_updated: last_updated})
    |> Ecto.Changeset.put_embed(:collects, collects)
    |> Ecto.Changeset.put_embed(:meta, meta)
    |> Repo.update()
  end

  # check if the article is already in this folder
  @spec article_not_collect_in_folder(T.article_thread(), T.id(), [ArticleCollect.t()]) ::
          T.done()
  defp article_not_collect_in_folder(thread, article_id, collects) do
    with {:ok, info} <- match(thread) do
      already_collected =
        Enum.any?(collects, fn c ->
          article_id == Map.get(c, info.foreign_key)
        end)

      case already_collected do
        true -> raise_error(:already_collected_in_folder, "already collected in this folder")
        false -> {:ok, :pass}
      end
    end
  end

  defp do_list_collect_folders(filter, query) do
    %{page: page, size: size} = filter

    query
    |> filter_thread_ifneed(filter)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(page: page, size: size)
    |> done()
  end

  defp filter_thread_ifneed(query, %{thread: thread}) do
    field_name = "has_#{thread}"
    field_value = true

    # see https://stackoverflow.com/a/55922528/4050784
    query
    |> where([f], fragment("(?->>?)::boolean = ?", f.meta, ^field_name, ^field_value))
  end

  defp filter_thread_ifneed(query, _), do: query

  defp upsert_collect_folder_result({:ok, %{add_to_collect_folder: result}}), do: {:ok, result}

  defp upsert_collect_folder_result({:ok, %{rm_from_collect_folder: result}}) do
    {:ok, result}
  end

  defp upsert_collect_folder_result({:error, _, result, _steps}) do
    {:error, result}
  end
end
