defmodule MastaniServer.CMS.Delegate.ArticleReaction do
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false

  alias MastaniServer.{Repo, Accounts}
  # alias Helper.QueryBuilder
  alias Helper.ORM

  @doc """
  favorite / star / watch CMS contents like post / tuts / video ...
  """
  # TODO: def reaction(thread, react, thread_id, %Accounts.User{id: user_id}) when valid_reaction(thread, react) do
  def reaction(thread, react, thread_id, %Accounts.User{id: user_id})
      when valid_reaction(thread, react) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, content} <- ORM.find(action.target, thread_id),
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
  def undo_reaction(thread, react, thread_id, %Accounts.User{id: user_id})
      when valid_reaction(thread, react) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, content} <- ORM.find(action.target, thread_id) do
      the_user = dynamic([u], u.user_id == ^user_id)

      where =
        case thread do
          :post ->
            dynamic([p], p.post_id == ^content.id and ^the_user)

          :job ->
            dynamic([p], p.job_id == ^content.id and ^the_user)
            # :star -> dynamic([p], p.star_id == ^content.id and ^the_user)
        end

      query = from(f in action.reactor, where: ^where)

      case Repo.one(query) do
        nil ->
          {:error, "record not found"}

        record ->
          Repo.delete(record)
          {:ok, content}
      end
    end
  end
end
