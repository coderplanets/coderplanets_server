defmodule GroupherServer.Accounts.Delegate.CollectFolder do
  @moduledoc """
  user FavoriteCategory related
  """
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Utils.Matcher2

  alias Helper.QueryBuilder

  import Helper.ErrorCode
  import Helper.Utils, only: [done: 1, count_words: 1]

  import ShortMaps

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.{CollectFolder, Embeds, FavoriteCategory, User}
  alias CMS.{PostFavorite, JobFavorite, RepoFavorite}

  alias Ecto.Multi

  # @max_article_count_per_collect_folder 300

  @default_threads_flags Embeds.CollectFolderMeta.default_threads_flags()
  @default_meta Embeds.CollectFolderMeta.default_meta()
  @supported_collect_threads [:post, :job]

  def list_collect_folders(filter, %User{id: user_id}) do
    query = CollectFolder |> where([c], c.user_id == ^user_id and not c.private)

    do_list_collect_folders(filter, query)
  end

  def list_collect_folders(filter, %User{id: user_id}, %User{id: cur_user_id}) do
    query =
      if cur_user_id == user_id,
        do: CollectFolder |> where([c], c.user_id == ^user_id),
        else: CollectFolder |> where([c], c.user_id == ^user_id and not c.private)

    do_list_collect_folders(filter, query)
  end

  def list_collect_folder_articles(folder_id, filter, %User{id: user_id}) do
    with {:ok, folder} <- ORM.find_by(CollectFolder, %{id: folder_id, user_id: user_id}) do
      Repo.preload(folder.collects, @supported_collect_threads)
      |> ORM.embeds_paginater(filter)
      |> ORM.extract_articles(@supported_collect_threads)
      |> done()
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

  def delete_collect_folder(id) do
    # 1. downgrade_achievment
    # 2. delete collect-folder
    CollectFolder |> ORM.find_delete!(id)
  end

  def add_to_collect(thread, article_id, folder_id, %User{id: cur_user_id} = user) do
    with {:ok, folder} <- ORM.find(CollectFolder, folder_id),
         {:ok, _} <- article_not_collect_in_folder(thread, article_id, folder.collects),
         # 是否是该 folder 的 owner ?
         true <- cur_user_id == folder.user_id do
      Multi.new()
      # |> Multi.run(:downgrade_achievement, fn _, _ ->
      #   # TODO: move to CMS
      #   {:ok, :pass}
      # end)
      |> Multi.run(:create_article_collect, fn _, _ ->
        CMS.collect_article_ifneed(thread, article_id, user)
      end)
      |> Multi.run(:set_article_collect_folder, fn _,
                                                   %{create_article_collect: article_collect} ->
        CMS.set_collect_folder(article_collect, folder)
      end)
      |> Multi.run(:add_to_collect_folder, fn _, %{create_article_collect: article_collect} ->
        collects = [article_collect] ++ folder.collects
        total_count = length(collects)
        last_updated = Timex.today() |> Timex.to_datetime()

        thread_count =
          Enum.filter(collects, &(not is_nil(Map.get(&1, :"#{thread}_id")))) |> length

        thread_count_map = %{"#{thread}_count": thread_count}

        meta =
          folder.meta
          |> Map.merge(%{"has_#{thread}": true})
          |> Map.merge(thread_count_map)
          |> Map.from_struct()
          |> Map.delete(:id)

        folder
        |> Ecto.Changeset.change(%{total_count: total_count, last_updated: last_updated})
        |> Ecto.Changeset.put_embed(:collects, collects)
        |> Ecto.Changeset.put_embed(:meta, meta)
        |> Repo.update()
      end)
      |> Repo.transaction()
      |> upsert_collect_folder_result()
    end
  end

  def remove_from_collect(thread, article_id, folder_id, %User{id: cur_user_id} = user) do
    with {:ok, folder} <- ORM.find(CollectFolder, folder_id),
         # 是否是该 folder 的 owner ?
         true <- cur_user_id == folder.user_id do
      Multi.new()
      |> Multi.run(:delete_article_collect, fn _, _ ->
        CMS.undo_collect_article_ifneed(thread, article_id, user)
      end)
      |> Multi.run(:undo_set_article_collect_folder, fn _,
                                                        %{delete_article_collect: article_collect} ->
        CMS.undo_set_collect_folder(article_collect, folder)
      end)
      |> Multi.run(:remove_from_collect_folder, fn _,
                                                   %{delete_article_collect: article_collect} ->
        # 不能用 -- 语法，因为两个结构体的 meta 信息不同，摔。
        collects = Enum.reject(folder.collects, &(&1.id == article_collect.id))
        total_count = length(collects)
        last_updated = Timex.today() |> Timex.to_datetime()

        # covert [:post, :job] into -> %{has_post: boolean, has_job: boolean}
        threads = collects |> Enum.map(&thread_to_atom(&1.thread)) |> Enum.uniq()

        thread_count =
          Enum.filter(collects, &(not is_nil(Map.get(&1, :"#{thread}_id")))) |> length

        threads_flag_map =
          Map.merge(@default_threads_flags, Map.new(threads, &{:"has_#{&1}", true}))

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
      end)
      |> Repo.transaction()
      |> upsert_collect_folder_result()
    end
  end

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

  # @spec unset_favorites_result({:ok, map()}) :: {:ok, FavoriteCategory.t() }
  defp upsert_collect_folder_result({:ok, %{add_to_collect_folder: result}}), do: {:ok, result}

  defp upsert_collect_folder_result({:ok, %{remove_from_collect_folder: result}}) do
    {:ok, result}
  end

  defp upsert_collect_folder_result({:error, _, result, _steps}) do
    {:error, result}
  end

  ######## ####### ####### ####### ####### ######
  ######## ####### ####### ####### ####### ######
  ######## ####### ####### ####### ####### ######
  ######## ####### ####### ####### ####### ######

  def delete_favorite_category(%User{id: user_id}, id) do
    with {:ok, category} <- FavoriteCategory |> ORM.find_by(~m(id user_id)a) do
      Multi.new()
      |> Multi.run(:downgrade_achievement, fn _, _ ->
        # find user favvoried-contents(posts & jobs) 's author,
        # and downgrade their's acieveents
        # NOTE: this is too fucking violent and should be refactor later
        # we find favroted posts/jobs author_ids then doengrade their achievement
        # this implentment is limited, if the user have lots contents in a favoreted-category
        # ant those contents have diffenert author each, it may be fucked
        # should be in a queue job or sth
        {:ok, post_author_ids} = affected_author_ids(:post, CMS.PostFavorite, category)
        {:ok, job_author_ids} = affected_author_ids(:job, CMS.JobFavorite, category)
        {:ok, repo_author_ids} = affected_author_ids(:repo, CMS.RepoFavorite, category)

        # author_ids_list = count_words(total_author_ids) |> Map.to_list
        author_ids_list =
          (post_author_ids ++ job_author_ids ++ repo_author_ids)
          |> count_words
          |> Map.to_list()

        # NOTE: if the contents have too many unique authors, it may be crash the server
        # so limit size to 20 unique authors
        Enum.each(author_ids_list |> Enum.slice(0, 20), fn {author_id, count} ->
          Accounts.downgrade_achievement(%User{id: author_id}, :favorite, count)
        end)

        {:ok, %{done: true}}
      end)
      |> Multi.run(:delete_category, fn _, _ ->
        category |> ORM.delete()
      end)
      |> Repo.transaction()
      |> delete_favorites_result()
    end
  end

  # NOTE: this is too fucking violent and should be refactor later
  # we find favroted posts/jobs author_ids then doengrade their achievement
  # this implentment is limited, if the user have lots contents in a favoreted-category
  # ant those contents have diffenert author each, it may be fucked
  defp affected_author_ids(thread, queryable, category) do
    query =
      from(
        fc in queryable,
        join: content in assoc(fc, ^thread),
        join: author in assoc(content, :author),
        where: fc.category_id == ^category.id,
        select: author.user_id
      )

    case ORM.find_all(query, %{page: 1, size: 50}) do
      {:ok, paged_contents} ->
        {:ok, paged_contents |> Map.get(:entries)}

      {:error, _} ->
        {:ok, []}
    end
  end

  defp delete_favorites_result({:ok, %{downgrade_achievement: result}}), do: {:ok, result}

  defp delete_favorites_result({:error, :delete_category, %Ecto.Changeset{} = result, _steps}) do
    {:error, result}
  end

  defp delete_favorites_result({:error, :delete_category, _result, _steps}) do
    {:error, [message: "delete category fails", code: ecode(:delete_fails)]}
  end

  defp delete_favorites_result({:error, :delete_favorite_record, _result, _steps}) do
    {:error, [message: "delete delete_favorite_record fails", code: ecode(:delete_fails)]}
  end

  def list_favorite_categories(
        %User{id: user_id},
        %{private: private},
        %{page: page, size: size} = filter
      ) do
    query =
      case private do
        true ->
          FavoriteCategory
          |> where([c], c.user_id == ^user_id)

        false ->
          FavoriteCategory
          |> where([c], c.user_id == ^user_id)
          |> where([c], c.private == false)
      end

    query
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(page: page, size: size)
    |> done()
  end

  @doc """
  set category for favorited content (post, job ...)
  """
  def set_favorites(%User{} = user, thread, content_id, category_id) do
    with {:ok, favorite_category} <-
           FavoriteCategory |> ORM.find_by(%{user_id: user.id, id: category_id}) do
      Multi.new()
      |> Multi.run(:favorite_content, fn _, _ ->
        with {:ok, content_favorite} <- find_content_favorite(thread, content_id, user.id) do
          check_dup_category(content_favorite, favorite_category)
        else
          {:error, _} ->
            case CMS.reaction(thread, :favorite, content_id, user) do
              {:ok, _} -> find_content_favorite(thread, content_id, user.id)
              {:error, reason} -> {:error, reason}
            end
        end
      end)
      |> Multi.run(:dec_old_category_count, fn _, %{favorite_content: content_favorite} ->
        with false <- is_nil(content_favorite.category_id),
             {:ok, old_category} <- FavoriteCategory |> ORM.find(content_favorite.category_id) do
          old_category
          |> ORM.update(%{total_count: max(old_category.total_count - 1, 0)})
        else
          true -> {:ok, ""}
          reason -> {:error, reason}
        end
      end)
      |> Multi.run(:update_content_category_id, fn _, %{favorite_content: content_favorite} ->
        content_favorite |> ORM.update(%{category_id: favorite_category.id})
      end)
      |> Multi.run(:update_category_info, fn _, _ ->
        last_updated = Timex.today() |> Timex.to_datetime()

        favorite_category
        |> ORM.update(%{
          last_updated: last_updated,
          total_count: favorite_category.total_count + 1
        })
      end)
      |> Repo.transaction()
      |> set_favorites_result()
    end
  end

  defp set_favorites_result({:ok, %{update_category_info: result}}), do: {:ok, result}

  defp set_favorites_result({:error, :favorite_content, result, _steps}) do
    # {:error, [message: "favorite content fails", code: ecode(:react_fails)]}
    {:error, result}
  end

  defp set_favorites_result({:error, :dec_old_category_count, _result, _steps}) do
    {:error, [message: "update old category count fails", code: ecode(:update_fails)]}
  end

  defp set_favorites_result({:error, :update_content_category_id, _result, _steps}) do
    {:error, [message: "update category content fails", code: ecode(:update_fails)]}
  end

  defp set_favorites_result({:error, :update_count, _result, _steps}) do
    {:error, [message: "inc total count fails", code: ecode(:update_fails)]}
  end

  def unset_favorites(%User{} = user, thread, content_id, category_id) do
    with {:ok, favorite_category} <-
           FavoriteCategory |> ORM.find_by(%{user_id: user.id, id: category_id}) do
      Multi.new()
      |> Multi.run(:undo_favorite_action, fn _, _ ->
        CMS.undo_reaction(thread, :favorite, content_id, user)
      end)
      |> Multi.run(:update_category_info, fn _, _ ->
        last_updated = Timex.today() |> Timex.to_datetime()

        favorite_category
        |> ORM.update(%{
          last_updated: last_updated,
          total_count: max(favorite_category.total_count - 1, 0)
        })
      end)
      |> Repo.transaction()
      |> unset_favorites_result()
    end
  end

  # @spec unset_favorites_result({:ok, map()}) :: {:ok, FavoriteCategory.t() }
  defp unset_favorites_result({:ok, %{update_category_info: result}}), do: {:ok, result}

  defp unset_favorites_result({:error, :undo_favorite_action, result, _steps}) do
    # {:error, [message: "favorite content fails", code: ecode(:react_fails)]}
    {:error, result}
  end

  defp unset_favorites_result({:error, :dec_count, result, _steps}) do
    {:error, result}
  end

  defp find_content_favorite(:post, content_id, user_id),
    do: PostFavorite |> ORM.find_by(%{post_id: content_id, user_id: user_id})

  defp find_content_favorite(:job, content_id, user_id),
    do: JobFavorite |> ORM.find_by(%{job_id: content_id, user_id: user_id})

  defp find_content_favorite(:repo, content_id, user_id),
    do: RepoFavorite |> ORM.find_by(%{repo_id: content_id, user_id: user_id})

  defp check_dup_category(content, category) do
    case content.category_id !== category.id do
      true -> {:ok, content}
      false -> {:error, [message: "viewer has already categoried", code: ecode(:already_did)]}
    end
  end

  defp thread_to_atom(thread) when is_binary(thread) do
    thread |> String.downcase() |> String.to_atom()
  end
end
