defmodule MastaniServer.CMS.Delegate.CommunityCURD do
  @moduledoc """
  community curd
  """
  import Ecto.Query, warn: false
  import MastaniServer.CMS.Utils.Matcher
  import Helper.Utils, only: [done: 1, map_atom_value: 2]
  import MastaniServer.CMS.Delegate.ArticleCURD, only: [ensure_author_exists: 1]
  import ShortMaps

  alias Helper.ORM
  alias Helper.QueryBuilder
  alias MastaniServer.{Accounts, Repo}

  alias MastaniServer.CMS.{
    Category,
    Community,
    CommunityEditor,
    CommunitySubscriber,
    Tag,
    Topic,
    Thread
  }

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

  def update_editor(%Community{id: community_id}, title, %Accounts.User{id: user_id}) do
    clauses = ~m(user_id community_id)a

    with {:ok, _} <- CommunityEditor |> ORM.update_by(clauses, ~m(title)a) do
      Accounts.User |> ORM.find(user_id)
    end
  end

  @doc """
  create a Tag base on type: post / tuts / videos ...
  """
  def create_tag(thread, attrs, %Accounts.User{id: user_id}) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, author} <- ensure_author_exists(%Accounts.User{id: user_id}),
         {:ok, _community} <- ORM.find(Community, attrs.community_id),
         {:ok, topic} = find_or_insert_topic(attrs) do

      attrs =
        attrs
        |> Map.merge(%{author_id: author.id, topic_id: topic.id})
        |> map_atom_value(:string)
        |> Map.merge(%{thread: attrs.thread |> to_string |> String.downcase()})

      action.reactor |> ORM.create(attrs)
    end
  end

  def update_tag(%{id: _id} = attrs) do
    ~m(id title color)a = attrs |> map_atom_value(:string)

    with {:ok, %{id: topic_id}} = find_or_insert_topic(attrs) do
      Tag
      |> ORM.find_update(~m(id title color color topic_id)a)
    end
  end

  @doc """
  get tags belongs to a community / thread
  """
  def get_tags(%Community{id: community_id}, thread, topic) when not is_nil(community_id) do
    # thread = thread |> to_string |> String.upcase()
    # topic = topic |> to_string |> String.upcase()
    thread = thread |> to_string |> String.downcase()
    topic = topic |> to_string |> String.downcase()

    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> join(:inner, [t], cp in assoc(t, :topic))
    |> where([t, c, cp], c.id == ^community_id and t.thread == ^thread and cp.title == ^topic)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  def get_tags(%Community{id: community_id}, thread) when not is_nil(community_id) do
    # thread = thread |> to_string |> String.upcase()
    thread = thread |> to_string |> String.downcase()

    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.id == ^community_id and t.thread == ^thread)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  def get_tags(%Community{raw: community_raw}, thread) do
    thread = thread |> to_string |> String.downcase()

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

  @doc """
  return community geo infos
  """
  def community_geo_info(%Community{id: community_id}) do
    with {:ok, community} <- ORM.find(Community, community_id) do
      geo_info_data =
        community.geo_info
        |> Map.get("data")
        |> Enum.map(fn data ->
          for {key, val} <- data, into: %{}, do: {String.to_atom(key), val}
        end)
        |> Enum.reject(&(&1.value <= 0))

      {:ok, geo_info_data}
    end
  end

  defp find_or_insert_topic(%{topic: title} = attrs) when is_binary(title) do
    title = title |> to_string() |> String.downcase()
    thread = attrs.thread |> to_string() |> String.downcase()

    ORM.findby_or_insert(Topic, %{title: title}, %{
      title: title,
      thread: thread,
      raw: title
    })
  end

  defp find_or_insert_topic(%{thread: thread}) do
    find_or_insert_topic(%{topic: "index", thread: thread})
  end

  defp find_or_insert_topic(_attrs) do
    find_or_insert_topic(%{topic: "index", thread: :post})
  end
end
