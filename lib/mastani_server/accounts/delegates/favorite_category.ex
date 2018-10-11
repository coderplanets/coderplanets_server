defmodule MastaniServer.Accounts.Delegate.FavoriteCategory do
  @moduledoc """
  user FavoriteCategory related
  """
  import Ecto.Query, warn: false

  import Helper.ErrorCode
  import Helper.Utils, only: [done: 1]

  import ShortMaps

  alias Helper.ORM
  alias MastaniServer.Accounts.{FavoriteCategory, User}
  alias MastaniServer.{CMS, Repo}

  alias Ecto.Multi

  def create_favorite_category(%User{id: user_id}, %{title: title} = attrs) do
    with {:error, _} <- FavoriteCategory |> ORM.find_by(~m(user_id title)a) do
      FavoriteCategory |> ORM.create(attrs |> Map.merge(~m(user_id)a))
    else
      {:ok, category} ->
        {:error, [message: "#{category.title} already exsits", code: ecode(:already_exsit)]}
    end
  end

  def update_favorite_category(%User{id: user_id}, %{id: id} = attrs) do
    with {:ok, category} <- FavoriteCategory |> ORM.find_by(~m(id user_id)a) do
      category |> ORM.update(attrs)
    end
  end

  def delete_favorite_category(%User{id: user_id}, id) do
    with {:ok, category} <- FavoriteCategory |> ORM.find_by(~m(id user_id)a) do
      Multi.new()
      |> Multi.run(:delete_category, fn _ ->
        category |> ORM.delete()
      end)
      |> Multi.run(:delete_favorite_record, fn _ ->
        query =
          from(
            pf in CMS.PostFavorite,
            where: pf.user_id == ^user_id,
            where: pf.category_id == ^category.id
          )

        query |> Repo.delete_all() |> done()
      end)
      |> Repo.transaction()
      |> delete_favorites_result()
    end
  end

  defp delete_favorites_result({:ok, %{delete_favorite_record: result}}), do: {:ok, result}

  defp delete_favorites_result({:error, :delete_category, _result, _steps}) do
    {:error, [message: "delete category fails", code: ecode(:delete_fails)]}
  end

  defp delete_favorites_result({:error, :delete_favorite_record, _result, _steps}) do
    {:error, [message: "delete delete_favorite_record fails", code: ecode(:delete_fails)]}
  end

  def list_favorite_categories(
        %User{id: user_id},
        %{private: private},
        %{page: page, size: size}
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
    |> ORM.paginater(page: page, size: size)
    |> done()
  end

  alias CMS.{PostFavorite, JobFavorite, VideoFavorite}

  @doc """
  set category for favorited content (post, job, video ...)
  """
  def set_favorites(%User{} = user, thread, content_id, category_id) do
    with {:ok, favorite_category} <-
           FavoriteCategory |> ORM.find_by(%{user_id: user.id, id: category_id}) do
      Multi.new()
      |> Multi.run(:favorite_content, fn _ ->
        case find_content_favorite(thread, content_id, user.id) do
          {:ok, content_favorite} -> check_dup_category(content_favorite, favorite_category)
          {:error, _} -> CMS.reaction(thread, :favorite, content_id, user)
        end
      end)
      |> Multi.run(:update_category_id, fn _ ->
        {:ok, content_favorite} = find_content_favorite(thread, content_id, user.id)

        content_favorite |> ORM.update(%{category_id: favorite_category.id})
      end)
      |> Multi.run(:inc_count, fn _ ->
        favorite_category |> ORM.update(%{total_count: favorite_category.total_count + 1})
      end)
      |> Repo.transaction()
      |> set_favorites_result()
    end
  end

  defp set_favorites_result({:ok, %{inc_count: result}}), do: {:ok, result}

  defp set_favorites_result({:error, :favorite_content, result, _steps}) do
    # {:error, [message: "favorite content fails", code: ecode(:react_fails)]}
    {:error, result}
  end

  defp set_favorites_result({:error, :update_category_id, _result, _steps}) do
    {:error, [message: "update category content fails", code: ecode(:update_fails)]}
  end

  defp set_favorites_result({:error, :update_count, _result, _steps}) do
    {:error, [message: "inc total count fails", code: ecode(:update_fails)]}
  end

  def unset_favorites(%User{} = user, thread, content_id, category_id) do
    with {:ok, favorite_category} <-
           FavoriteCategory |> ORM.find_by(%{user_id: user.id, id: category_id}) do
      Multi.new()
      |> Multi.run(:remove_favorite_record, fn _ ->
        {:ok, content_favorite} = find_content_favorite(thread, content_id, user.id)

        content_favorite |> ORM.delete()
      end)
      |> Multi.run(:dec_count, fn _ ->
        favorite_category |> ORM.update(%{total_count: max(favorite_category.total_count - 1, 0)})
      end)
      |> Repo.transaction()
      |> unset_favorites_result()
    end
  end

  # @spec unset_favorites_result({:ok, map()}) :: {:ok, FavoriteCategory.t() }
  defp unset_favorites_result({:ok, %{dec_count: result}}), do: {:ok, result}

  defp unset_favorites_result({:error, :remove_favorite_record, result, _steps}) do
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
      true -> {:ok, ""}
      false -> {:error, [message: "viewer has already categoried", code: ecode(:already_did)]}
    end
  end
end
