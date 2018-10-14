defmodule MastaniServer.CMS.Delegate.FavoritedContents do
  @moduledoc """
  CURD operation on post/job/video ...
  """
  alias Helper.ORM

  import Ecto.Query, warn: false
  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS

  def favorited_category(:post, id, %User{id: user_id}) do
    case ORM.find_by(CMS.PostFavorite, post_id: id, user_id: user_id) do
      {:ok, post_favorite} ->
        {:ok, post_favorite.category_id}

      _ ->
        {:ok, nil}
    end
  end

  def favorited_category(:job, id, %User{id: user_id}) do
    case ORM.find_by(CMS.JobFavorite, job_id: id, user_id: user_id) do
      {:ok, job_favorite} ->
        {:ok, job_favorite.category_id}

      _ ->
        {:ok, nil}
    end
  end

  def favorited_category(:video, id, %User{id: user_id}) do
    case ORM.find_by(CMS.VideoFavorite, video_id: id, user_id: user_id) do
      {:ok, video_favorite} ->
        {:ok, video_favorite.category_id}

      _ ->
        {:ok, nil}
    end
  end
end
