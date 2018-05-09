defmodule MastaniServer.CMS.Delegate.CommunityCURD do
  # TODO docs:  include community / editors / curd
  import Ecto.Query, warn: false
  import MastaniServer.CMS.Utils.Matcher
  import Helper.Utils, only: [done: 1]
  import ShortMaps

  alias MastaniServer.{Repo, Accounts}

  alias MastaniServer.CMS.{
    Community,
    CommunityEditor,
    CommunitySubscriber,
    Thread
  }

  alias MastaniServer.CMS.Delegate.PassportCURD
  alias Helper.QueryBuilder

  alias Helper.ORM

  def create_community(attrs), do: Community |> ORM.create(attrs)

  @doc """
  return paged community subscribers
  """
  def community_members(:editors, %Community{id: id}, filters) do
    load_community_members(id, CommunityEditor, filters)
  end

  def community_members(:subscribers, %Community{id: id}, filters) do
    load_community_members(id, CommunitySubscriber, filters)
  end

  defp load_community_members(id, modal, %{page: page, size: size} = filters) do
    modal
    |> where([c], c.community_id == ^id)
    |> QueryBuilder.load_inner_users(filters)
    |> ORM.paginater(page: page, size: size)
    |> done()
  end

  def update_editor(%Accounts.User{id: user_id}, %Community{id: community_id}, title) do
    clauses = ~m(user_id community_id)a

    with {:ok, _} <- CommunityEditor |> ORM.update_by(clauses, ~m(title)a) do
      Accounts.User |> ORM.find(user_id)
    end
  end

  def delete_editor(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, _} <- ORM.findby_delete(CommunityEditor, ~m(user_id community_id)a),
         {:ok, _} <- PassportCURD.delete_passport(%Accounts.User{id: user_id}) do
      Accounts.User |> ORM.find(user_id)
    end
  end

  @doc """
  create a Tag base on type: post / tuts / videos ...
  """
  def create_tag(part, attrs) when valid_part(part) do
    with {:ok, action} <- match_action(part, :tag),
         {:ok, community} <- ORM.find_by(Community, title: attrs.community) do
      attrs = attrs |> Map.merge(%{community_id: community.id})
      action.reactor |> ORM.create(attrs)
    end
  end

  # TODO: use comunityId
  def get_tags(community, part) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.title == ^community and t.part == ^part)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  @doc """
  TODO: create_thread
  """
  def create_thread(attrs), do: Thread |> ORM.create(attrs)
end
