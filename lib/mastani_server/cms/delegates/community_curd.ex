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
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  def update_editor(%Accounts.User{id: user_id}, %Community{id: community_id}, title) do
    clauses = ~m(user_id community_id)a

    with {:ok, _} <- CommunityEditor |> ORM.update_by(clauses, ~m(title)a) do
      Accounts.User |> ORM.find(user_id)
    end
  end

  @doc """
  create a Tag base on type: post / tuts / videos ...
  """
  def create_tag(thread, attrs, %Accounts.User{id: user_id}) when valid_thread(thread) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, author} <- ensure_author_exists(%Accounts.User{id: user_id}),
         {:ok, _community} <- ORM.find(Community, attrs.community_id) do
      attrs = attrs |> Map.merge(%{author_id: author.id})
      attrs = attrs |> map_atom_value(:string)

      action.reactor |> ORM.create(attrs)
    end
  end

  def update_tag(%{id: _id} = attrs) do
    attrs = attrs |> map_atom_value(:string)
    Tag |> ORM.find_update(%{id: attrs.id, title: attrs.title, color: attrs.color})
  end

  @doc """
  get tags belongs to a community / thread
  """
  def get_tags(%Community{id: community_id}, thread) when not is_nil(community_id) do
    thread = to_string(thread)

    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.id == ^community_id and t.thread == ^thread)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  def get_tags(%Community{raw: community_raw}, thread) when not is_nil(community_raw) do
    thread = to_string(thread)

    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.raw == ^community_raw and t.thread == ^thread)
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
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  def create_category(%Category{title: title, raw: raw}, %Accounts.User{id: user_id}) do
    with {:ok, author} <- ensure_author_exists(%Accounts.User{id: user_id}) do
      Category |> ORM.create(%{title: title, raw: raw, author_id: author.id})
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
  def create_thread(attrs) do
    raw = to_string(attrs.raw)
    title = attrs.title
    index = attrs |> Map.get(:index, 0)

    Thread |> ORM.create(~m(title raw index)a)
  end
end
