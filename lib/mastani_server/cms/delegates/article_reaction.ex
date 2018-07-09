defmodule MastaniServer.CMS.Delegate.ArticleReaction do
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false

  alias MastaniServer.{Repo, Accounts}
  # alias Helper.QueryBuilder
  alias Helper.ORM

  @doc """
  favorite / star / watch CMS contents like post / tuts / video ...
  """
  def reaction(thread, react, content_id, %Accounts.User{id: user_id})
      when valid_reaction(thread, react) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, content} <- ORM.find(action.target, content_id),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      attrs = Map.put(%{}, "user_id", user.id) |> Map.put("#{thread}_id", content.id)

      action.reactor
      |> ORM.create(attrs)
      |> case do
        {:ok, _} -> {:ok, content}
        {:error, error} -> {:error, error}
      end
    end
  end

  @doc """
  unfavorite / unstar / unwatch CMS contents like post / tuts / video ...
  """
  def undo_reaction(thread, react, content_id, %Accounts.User{id: user_id})
      when valid_reaction(thread, react) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, content} <- ORM.find(action.target, content_id) do
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
  end

  defp dynamic_reaction_where(:post, id, user_where) do
    dynamic([p], p.post_id == ^id and ^user_where)
  end

  defp dynamic_reaction_where(:job, id, user_where) do
    dynamic([p], p.job_id == ^id and ^user_where)
  end
end
