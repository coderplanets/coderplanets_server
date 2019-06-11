defmodule GroupherServer.CMS.Delegate.FavoritedContents do
  @moduledoc """
  CURD operation on post/job/video ...
  """
  alias Helper.ORM

  import Ecto.Query, warn: false
  alias GroupherServer.Accounts.User
  alias GroupherServer.CMS

  def favorited_category(:post, id, %User{id: user_id}) do
    CMS.PostFavorite
    |> ORM.find_by(post_id: id, user_id: user_id)
    |> handle_reault
  end

  def favorited_category(:job, id, %User{id: user_id}) do
    CMS.JobFavorite
    |> ORM.find_by(job_id: id, user_id: user_id)
    |> handle_reault
  end

  def favorited_category(:video, id, %User{id: user_id}) do
    CMS.VideoFavorite
    |> ORM.find_by(video_id: id, user_id: user_id)
    |> handle_reault
  end

  def favorited_category(:repo, id, %User{id: user_id}) do
    CMS.RepoFavorite
    |> ORM.find_by(repo_id: id, user_id: user_id)
    |> handle_reault
  end

  defp handle_reault(result) do
    case result do
      {:ok, content} ->
        {:ok, content.category_id}

      _ ->
        {:ok, nil}
    end
  end
end
