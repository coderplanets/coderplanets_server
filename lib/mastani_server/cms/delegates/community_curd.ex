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
  def community_members(:editors, %Community{id: id} = community, filters)
      when not is_nil(id) do
    load_community_members(community, CommunityEditor, filters)
  end

  def community_members(:editors, %Community{raw: raw} = community, filters)
      when not is_nil(raw) do
    load_community_members(community, CommunityEditor, filters)
  end

  def community_members(:subscribers, %Community{id: id} = community, filters)
      when not is_nil(id) do
    load_community_members(community, CommunitySubscriber, filters)
  end

  def community_members(:subscribers, %Community{raw: raw} = community, filters)
      when not is_nil(raw) do
    load_community_members(community, CommunitySubscriber, filters)
  end

  @doc """
  update community editor
  """
  def update_editor(%Community{id: community_id}, title, %Accounts.User{id: user_id}) do
    clauses = ~m(user_id community_id)a

    with {:ok, _} <- CommunityEditor |> ORM.update_by(clauses, ~m(title)a) do
      Accounts.User |> ORM.find(user_id)
    end
  end

  @doc """
  create a Tag base on type: post / tuts / videos ...
  """
  # TODO: change to create_tag(community, thread, attrs, ....)
  def create_tag(%Community{id: community_id}, thread, attrs, %Accounts.User{id: user_id}) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, author} <- ensure_author_exists(%Accounts.User{id: user_id}),
         {:ok, _community} <- ORM.find(Community, community_id),
         {:ok, topic} = find_or_insert_topic(attrs) do
      attrs =
        attrs
        |> Map.merge(%{author_id: author.id, topic_id: topic.id, community_id: community_id})
        |> map_atom_value(:string)
        |> Map.merge(%{thread: thread |> to_string |> String.downcase()})

      action.reactor |> ORM.create(attrs)
    end
  end

  def update_tag(%{id: _id} = attrs) do
    ~m(id title color)a = attrs |> map_atom_value(:string)

    with {:ok, %{id: topic_id}} = find_or_insert_topic(attrs) do
      Tag
      |> ORM.find_update(~m(id title color topic_id)a)
    end
  end

  @doc """
  get all tags belongs to a community
  """
  def get_tags(%Community{id: community_id}) when not is_nil(community_id) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c, cp], c.id == ^community_id)
    |> Repo.all()
    |> done()
  end

  def get_tags(%Community{raw: community_raw}) when not is_nil(community_raw) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c, cp], c.raw == ^community_raw)
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

  def get_tags(%Community{raw: community_raw}, thread, topic) when not is_nil(community_raw) do
    # thread = thread |> to_string |> String.upcase()
    # topic = topic |> to_string |> String.upcase()
    thread = thread |> to_string |> String.downcase()
    topic = topic |> to_string |> String.downcase()

    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> join(:inner, [t], cp in assoc(t, :topic))
    |> where([t, c, cp], c.raw == ^community_raw and t.thread == ^thread and cp.title == ^topic)
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

    result = get_tags_query(community_raw, thread)

    case result do
      {:ok, []} ->
        with {:ok, community} <- ORM.find_by(Community, aka: community_raw) do
          get_tags_query(community.raw, thread)
        else
          _ -> {:ok, []}
        end

      {:ok, ret} ->
        {:ok, ret}

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_tags_query(community_raw, thread) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.raw == ^community_raw and t.thread == ^thread)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  def create_category(attrs, %Accounts.User{id: user_id}) do
    with {:ok, author} <- ensure_author_exists(%Accounts.User{id: user_id}) do
      attrs = attrs |> Map.merge(%{author_id: author.id})
      Category |> ORM.create(attrs)
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

  @doc "count the total threads in community"
  def count(%Community{id: id}, :threads) do
    with {:ok, community} <- ORM.find(Community, id, preload: :threads) do
      {:ok, length(community.threads)}
    end
  end

  @doc "count the total tags in community"
  def count(%Community{id: id}, :tags) do
    with {:ok, community} <- ORM.find(Community, id) do
      result =
        Tag
        |> where([t], t.community_id == ^community.id)
        |> ORM.paginater(page: 1, size: 1)

      {:ok, result.total_count}
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
    find_or_insert_topic(%{topic: "posts", thread: thread})
  end

  defp find_or_insert_topic(_attrs) do
    find_or_insert_topic(%{topic: "posts", thread: :post})
  end

  defp load_community_members(%Community{id: id}, queryable, %{page: page, size: size} = filters)
       when not is_nil(id) do
    queryable
    |> where([c], c.community_id == ^id)
    |> QueryBuilder.load_inner_users(filters)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  defp load_community_members(
         %Community{raw: raw},
         queryable,
         %{page: page, size: size} = filters
       ) do
    queryable
    |> join(:inner, [member], c in assoc(member, :community))
    |> where([member, c], c.raw == ^raw)
    |> join(:inner, [member], u in assoc(member, :user))
    |> select([member, c, u], u)
    |> QueryBuilder.filter_pack(filters)
    # |> QueryBuilder.load_inner_users(filters)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end
end
