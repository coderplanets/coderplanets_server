defmodule MastaniServer.CMS.Delegate.ArticleReaction do
  @moduledoc """
  reaction[favorite, star, watch ...] on article [post, job, video...]
  """
  import Helper.Utils, only: [done: 1, done: 2]
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false
  import Helper.ErrorCode

  alias Helper.ORM
  alias MastaniServer.{Accounts, Repo}

  alias Accounts.User
  alias Ecto.Multi

  @doc """
  favorite / star / watch CMS contents like post / tuts / video ...
  """
  # when valid_reaction(thread, react) do
  def reaction(thread, react, content_id, %User{id: user_id}) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, content} <- ORM.find(action.target, content_id, preload: [author: :user]),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      Multi.new()
      |> Multi.run(:create_reaction_record, fn _ ->
        create_reaction_record(action, user, thread, content)
      end)
      |> Multi.run(:add_achievement, fn _ ->
        achiever_id = content.author.user_id
        Accounts.achieve(%User{id: achiever_id}, :add, react)
      end)
      |> Repo.transaction()
      |> reaction_result()
    end
  end

  defp reaction_result({:ok, %{create_reaction_record: result}}), do: result |> done()

  defp reaction_result({:error, :create_reaction_record, _result, _steps}) do
    {:error, [message: "create reaction fails", code: ecode(:react_fails)]}
  end

  defp reaction_result({:error, :add_achievement, _result, _steps}),
    do: {:error, [message: "achieve fails", code: ecode(:react_fails)]}

  defp create_reaction_record(action, %User{id: user_id}, thread, content) do
    attrs = %{} |> Map.put("user_id", user_id) |> Map.put("#{thread}_id", content.id)

    action.reactor
    |> ORM.create(attrs)
    |> done(with: content)
  end

  # ------
  @doc """
  unfavorite / unstar / unwatch CMS contents like post / tuts / video ...
  """
  # when valid_reaction(thread, react) do
  def undo_reaction(thread, react, content_id, %User{id: user_id}) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, content} <- ORM.find(action.target, content_id, preload: [author: :user]),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      Multi.new()
      |> Multi.run(:delete_reaction_record, fn _ ->
        delete_reaction_record(action, user, thread, content)
      end)
      |> Multi.run(:minus_achievement, fn _ ->
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

  defp dynamic_reaction_where(:video, id, user_where) do
    dynamic([p], p.video_id == ^id and ^user_where)
  end

  defp dynamic_reaction_where(:repo, id, user_where) do
    dynamic([p], p.repo_id == ^id and ^user_where)
  end
end
