defmodule MastaniServer.Accounts.Delegate.FavoriteCategory do
  @moduledoc """
  user FavoriteCategory related
  """
  import Ecto.Query, warn: false

  alias Helper.QueryBuilder

  import Helper.ErrorCode
  import Helper.Utils, only: [done: 1, count_words: 1]

  import ShortMaps

  alias Helper.ORM
  alias MastaniServer.Accounts
  alias MastaniServer.Accounts.{FavoriteCategory, User}
  alias MastaniServer.{CMS, Repo}

  alias CMS.{PostFavorite, JobFavorite, VideoFavorite}

  alias Ecto.Multi

  def create_favorite_category(%User{id: user_id}, %{title: title} = attrs) do
    with {:error, _} <- FavoriteCategory |> ORM.find_by(~m(user_id title)a) do
      last_updated = Timex.today() |> Timex.to_datetime()
      FavoriteCategory |> ORM.create(Map.merge(~m(user_id last_updated)a, attrs))
    else
      {:ok, category} ->
        {:error, [message: "#{category.title} already exsits", code: ecode(:already_exsit)]}
    end
  end

  def update_favorite_category(%User{id: user_id}, %{id: id} = attrs) do
    with {:ok, category} <- FavoriteCategory |> ORM.find_by(~m(id user_id)a) do
      last_updated = Timex.today() |> Timex.to_datetime()
      category |> ORM.update(Map.merge(~m(last_updated)a, attrs))
    end
  end

  def delete_favorite_category(%User{id: user_id}, id) do
    with {:ok, category} <- FavoriteCategory |> ORM.find_by(~m(id user_id)a) do
      Multi.new()
      |> Multi.run(:downgrade_achievement, fn _ ->
        # find user favvoried-contents(posts & jobs & videos) 's author,
        # and downgrade their's acieveents
        # NOTE: this is too fucking violent and should be refactor later
        # we find favroted posts/jobs/videos author_ids then doengrade their achievement
        # this implentment is limited, if the user have lots contents in a favoreted-category
        # ant those contents have diffenert author each, it may be fucked
        # should be in a queue job or sth
        {:ok, post_author_ids} = affected_author_ids(:post, CMS.PostFavorite, category)
        {:ok, job_author_ids} = affected_author_ids(:job, CMS.JobFavorite, category)
        {:ok, video_author_ids} = affected_author_ids(:video, CMS.VideoFavorite, category)

        # author_ids_list = count_words(total_author_ids) |> Map.to_list
        author_ids_list =
          (post_author_ids ++ job_author_ids ++ video_author_ids) |> count_words |> Map.to_list()

        # NOTE: if the contents have too many unique authors, it may be crash the server
        # so limit size to 20 unique authors
        Enum.each(author_ids_list |> Enum.slice(0, 20), fn {author_id, count} ->
          Accounts.downgrade_achievement(%User{id: author_id}, :favorite, count)
        end)

        {:ok, %{done: true}}
      end)
      |> Multi.run(:delete_category, fn _ ->
        category |> ORM.delete()
      end)
      |> Repo.transaction()
      |> delete_favorites_result()
    end
  end

  # NOTE: this is too fucking violent and should be refactor later
  # we find favroted posts/jobs/videos author_ids then doengrade their achievement
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
  set category for favorited content (post, job, video ...)
  """
  def set_favorites(%User{} = user, thread, content_id, category_id) do
    with {:ok, favorite_category} <-
           FavoriteCategory |> ORM.find_by(%{user_id: user.id, id: category_id}) do
      Multi.new()
      |> Multi.run(:favorite_content, fn _ ->
        with {:ok, content_favorite} <- find_content_favorite(thread, content_id, user.id) do
          check_dup_category(content_favorite, favorite_category)
        else
          {:error, _} ->
            case CMS.reaction(thread, :favorite, content_id, user) do
              {:ok, _} -> find_content_favorite(thread, content_id, user.id)
              {:error, error} -> {:error, error}
            end
        end
      end)
      |> Multi.run(:dec_old_category_count, fn %{favorite_content: content_favorite} ->
        with false <- is_nil(content_favorite.category_id),
             {:ok, old_category} <- FavoriteCategory |> ORM.find(content_favorite.category_id) do
          old_category
          |> ORM.update(%{total_count: max(old_category.total_count - 1, 0)})
        else
          true -> {:ok, ""}
          error -> {:error, error}
        end
      end)
      |> Multi.run(:update_content_category_id, fn %{favorite_content: content_favorite} ->
        content_favorite |> ORM.update(%{category_id: favorite_category.id})
      end)
      |> Multi.run(:update_category_info, fn _ ->
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
      |> Multi.run(:undo_favorite_action, fn _ ->
        CMS.undo_reaction(thread, :favorite, content_id, user)
      end)
      |> Multi.run(:update_category_info, fn _ ->
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

  defp find_content_favorite(:video, content_id, user_id),
    do: VideoFavorite |> ORM.find_by(%{video_id: content_id, user_id: user_id})

  defp check_dup_category(content, category) do
    case content.category_id !== category.id do
      true -> {:ok, content}
      false -> {:error, [message: "viewer has already categoried", code: ecode(:already_did)]}
    end
  end
end
