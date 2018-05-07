defmodule MastaniServer.CMS.Delegate.ArticleReaction do
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false

  alias MastaniServer.{Repo, Accounts}
  # alias Helper.QueryBuilder
  alias Helper.ORM

  @doc """
  favorite / star / watch CMS contents like post / tuts / video ...
  """
  # TODO: def reaction(part, react, part_id, %Accounts.User{id: user_id}) when valid_reaction(part, react) do
  def reaction(part, react, part_id, %Accounts.User{id: user_id})
      when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- ORM.find(action.target, part_id),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      attrs = Map.put(%{}, "user_id", user.id) |> Map.put("#{part}_id", content.id)
      action.reactor |> ORM.create(attrs)
    end
  end

  @doc """
  unfavorite / unstar / unwatch CMS contents like post / tuts / video ...
  """
  def undo_reaction(part, react, part_id, %Accounts.User{id: user_id})
      when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- ORM.find(action.target, part_id) do
      the_user = dynamic([u], u.user_id == ^user_id)

      where =
        case part do
          :post -> dynamic([p], p.post_id == ^content.id and ^the_user)
          :star -> dynamic([p], p.star_id == ^content.id and ^the_user)
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
