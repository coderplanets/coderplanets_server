defmodule GroupherServer.CMS.Delegate.CommunityCURD do
  @moduledoc """
  community curd
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, strip_struct: 1, get_config: 2]
  import GroupherServer.CMS.Delegate.ArticleCURD, only: [ensure_author_exists: 1]
  import GroupherServer.CMS.Helper.Matcher
  import ShortMaps

  alias Helper.ORM
  alias Helper.QueryBuilder
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User

  alias CMS.{
    Embeds,
    ArticleTag,
    Category,
    Community,
    CommunityEditor,
    CommunitySubscriber,
    Thread
  }

  @default_meta Embeds.CommunityMeta.default_meta()
  @article_threads get_config(:article, :article_threads)

  def read_community(clauses, user), do: read_community(clauses) |> viewer_has_states(user)
  def read_community(%{id: id}), do: ORM.read(Community, id, inc: :views)
  def read_community(%{raw: raw} = clauses), do: do_read_community(clauses, raw)
  def read_community(%{title: title} = clauses), do: do_read_community(clauses, title)

  @doc """
  create a community
  """
  def create_community(%{user_id: user_id} = args) do
    with {:ok, author} <- ensure_author_exists(%User{id: user_id}) do
      args = args |> Map.merge(%{user_id: author.user_id, meta: @default_meta})
      Community |> ORM.create(args)
    end
  end

  @doc """
  update community
  """
  def update_community(id, args) do
    with {:ok, community} <- ORM.find(Community, id) do
      case community.meta do
        nil -> ORM.update(community, args |> Map.merge(%{meta: @default_meta}))
        _ -> ORM.update(community, args)
      end
    end
  end

  @doc """
  update editors_count of a community
  """
  def update_community_count_field(%Community{} = community, user_id, :editors_count, opt) do
    count_query = from(s in CommunityEditor, where: s.community_id == ^community.id)
    editors_count = Repo.aggregate(count_query, :count)
    community_meta = if is_nil(community.meta), do: @default_meta, else: community.meta

    editors_ids =
      case opt do
        :inc -> (community_meta.editors_ids ++ [user_id]) |> Enum.uniq()
        :dec -> (community_meta.editors_ids -- [user_id]) |> Enum.uniq()
      end

    meta = community_meta |> Map.put(:editors_ids, editors_ids) |> strip_struct

    community
    |> Ecto.Changeset.change(%{editors_count: editors_count})
    |> Ecto.Changeset.put_embed(:meta, meta)
    |> Repo.update()
  end

  @doc """
  update article_tags_count of a community
  """
  def update_community_count_field(%Community{} = community, :article_tags_count) do
    count_query = from(t in ArticleTag, where: t.community_id == ^community.id)
    article_tags_count = Repo.aggregate(count_query, :count)

    community
    |> Ecto.Changeset.change(%{article_tags_count: article_tags_count})
    |> Repo.update()
  end

  @doc """
  update subscribers_count of a community
  """
  def update_community_count_field(%Community{} = community, user_id, :subscribers_count, opt) do
    count_query = from(s in CommunitySubscriber, where: s.community_id == ^community.id)
    subscribers_count = Repo.aggregate(count_query, :count)
    community_meta = if is_nil(community.meta), do: @default_meta, else: community.meta

    subscribed_user_ids =
      case opt do
        :inc -> (community_meta.subscribed_user_ids ++ [user_id]) |> Enum.uniq()
        :dec -> (community_meta.subscribed_user_ids -- [user_id]) |> Enum.uniq()
      end

    meta = community_meta |> Map.put(:subscribed_user_ids, subscribed_user_ids) |> strip_struct

    community
    |> Ecto.Changeset.change(%{subscribers_count: subscribers_count})
    |> Ecto.Changeset.put_embed(:meta, meta)
    |> Repo.update()
  end

  def update_community_count_field(communities, thread) when is_list(communities) do
    case Enum.all?(communities, &({:ok, _} = update_community_count_field(&1, thread))) do
      true -> {:ok, :pass}
      false -> {:error, "update_community_count_field"}
    end
  end

  @doc """
  update thread / article count in community meta
  """
  def update_community_count_field(%Community{} = community, thread) do
    with {:ok, info} <- match(thread) do
      count_query =
        from(a in info.model,
          join: c in assoc(a, :communities),
          where: a.mark_delete == false,
          where: c.id == ^community.id
        )

      thread_article_count = Repo.aggregate(count_query, :count)
      community_meta = if is_nil(community.meta), do: @default_meta, else: community.meta

      meta = community_meta |> Map.put(:"#{thread}s_count", thread_article_count) |> strip_struct

      community
      |> Ecto.Changeset.change(%{articles_count: recount_articles_count(meta)})
      |> Ecto.Changeset.put_embed(:meta, meta)
      |> Repo.update()
    end
  end

  defp recount_articles_count(meta) do
    @article_threads |> Enum.reduce(0, &(&2 + Map.get(meta, :"#{&1}s_count")))
  end

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
  def update_editor(%Community{id: community_id}, title, %User{id: user_id}) do
    clauses = ~m(user_id community_id)a

    with {:ok, _} <- CommunityEditor |> ORM.update_by(clauses, ~m(title)a) do
      User |> ORM.find(user_id)
    end
  end

  def create_category(attrs, %User{id: user_id}) do
    with {:ok, author} <- ensure_author_exists(%User{id: user_id}) do
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
  def count(%Community{id: id}, :article_tags) do
    with {:ok, community} <- ORM.find(Community, id) do
      result =
        ArticleTag
        |> where([t], t.community_id == ^community.id)
        |> ORM.paginater(page: 1, size: 1)

      {:ok, result.total_count}
    end
  end

  defp do_read_community(clauses, aka) do
    case ORM.read_by(Community, clauses, inc: :views) do
      {:ok, community} -> {:ok, community}
      {:error, _} -> ORM.find_by(Community, aka: aka)
    end
  end

  defp viewer_has_states({:ok, community}, %User{id: user_id}) do
    viewer_has_states = %{
      viewer_has_subscribed: user_id in community.meta.subscribed_user_ids,
      viewer_is_editor: user_id in community.meta.editors_ids
    }

    {:ok, Map.merge(community, viewer_has_states)}
  end

  defp viewer_has_states({:error, reason}, _user), do: {:error, reason}

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
