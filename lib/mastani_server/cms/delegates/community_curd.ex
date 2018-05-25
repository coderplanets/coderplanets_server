defmodule MastaniServer.CMS.Delegate.CommunityCURD do
  # TODO docs:  include community / editors / curd
  import Ecto.Query, warn: false
  import MastaniServer.CMS.Utils.Matcher
  import Helper.Utils, only: [done: 1, map_atom_value: 2]
  import MastaniServer.CMS.Delegate.ArticleCURD, only: [ensure_author_exists: 1]
  import ShortMaps

  alias MastaniServer.{Repo, Accounts}

  alias MastaniServer.CMS.{
    Community,
    Category,
    CommunityEditor,
    CommunitySubscriber,
    Thread,
    Tag
  }

  alias MastaniServer.CMS.Delegate.PassportCURD
  alias Helper.QueryBuilder

  alias Helper.ORM

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
  def create_tag(part, attrs, %Accounts.User{id: user_id}) when valid_part(part) do
    with {:ok, action} <- match_action(part, :tag),
         {:ok, author} <- ensure_author_exists(%Accounts.User{id: user_id}),
         {:ok, _community} <- ORM.find(Community, attrs.community_id) do
      attrs = attrs |> Map.merge(%{author_id: author.id})
      attrs = attrs |> map_atom_value(:string)

      action.reactor |> ORM.create(attrs)
    end
  end

  @doc """
  get tags belongs to a community / part
  """
  def get_tags(%Community{id: communitId}, part) do
    part = to_string(part)

    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.id == ^communitId and t.part == ^part)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  @doc """
  get all paged tags
  """
  def get_tags(%{page: page, size: size} = filter) do
    Tag
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(page: page, size: size)
    |> done()
  end

  def create_category(%Category{title: title}, %Accounts.User{id: user_id}) do
    with {:ok, author} <- ensure_author_exists(%Accounts.User{id: user_id}) do
      Category |> ORM.create(%{title: title, author_id: author.id})
    end
  end

  def update_category(~m(%Category id title)a) do
    with {:ok, category} <- ORM.find(Category, id) do
      category |> ORM.update(~m(title)a)
    end
  end

  @doc """
  TODO: create_thread
  """
  def create_thread(attrs), do: Thread |> ORM.create(attrs)
end
