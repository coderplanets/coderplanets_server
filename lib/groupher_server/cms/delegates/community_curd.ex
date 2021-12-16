defmodule GroupherServer.CMS.Delegate.CommunityCURD do
  @moduledoc """
  community curd
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, strip_struct: 1, get_config: 2, plural: 1, ensure: 2]
  import GroupherServer.CMS.Delegate.ArticleCURD, only: [ensure_author_exists: 1]
  import GroupherServer.CMS.Helper.Matcher
  import ShortMaps

  alias Helper.ORM
  alias Helper.QueryBuilder
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.Model.User

  alias CMS.Model.{
    Embeds,
    ArticleTag,
    Category,
    Community,
    CommunityEditor,
    CommunitySubscriber,
    Thread
  }

  alias CMS.Constant

  @default_meta Embeds.CommunityMeta.default_meta()
  @article_threads get_config(:article, :threads)

  @default_user_meta Accounts.Model.Embeds.UserMeta.default_meta()
  @community_normal Constant.pending(:normal)
  @community_applying Constant.pending(:applying)

  @default_apply_category Constant.apply_category(:public)

  def read_community(raw, user), do: read_community(raw) |> viewer_has_states(user)
  def read_community(raw), do: do_read_community(raw)

  def paged_communities(filter, %User{id: user_id, meta: meta}) do
    with {:ok, paged_communtiies} <- paged_communities(filter) do
      %{entries: entries} = paged_communtiies

      entries =
        Enum.map(entries, fn community ->
          viewer_has_subscribed = community.id in meta.subscribed_communities_ids
          %{community | viewer_has_subscribed: viewer_has_subscribed}
        end)

      %{paged_communtiies | entries: entries} |> done
    end
  end

  def paged_communities(filter) do
    filter = filter |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Enum.into(%{})
    Community |> ORM.find_all(filter)
  end

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
  check if community exist
  """
  def is_community_exist?(raw) do
    case ORM.find_by(Community, raw: raw) do
      {:ok, _} -> {:ok, %{exist: true}}
      {:error, _} -> {:ok, %{exist: false}}
    end
  end

  def has_pending_community_apply?(%User{} = user) do
    with {:ok, paged_applies} <- paged_community_applies(user, %{page: 1, size: 1}) do
      case paged_applies.total_count > 0 do
        true -> {:ok, %{exist: true}}
        false -> {:ok, %{exist: false}}
      end
    end
  end

  def paged_community_applies(%User{} = user, %{page: page, size: size} = _filter) do
    Community
    |> where([c], c.pending == ^@community_applying)
    |> where([c], c.user_id == ^user.id)
    |> ORM.paginator(~m(page size)a)
    |> done
  end

  def apply_community(args) do
    with {:ok, community} <- create_community(Map.merge(args, %{pending: @community_applying})) do
      apply_msg = Map.get(args, :apply_msg, "")
      apply_category = Map.get(args, :apply_category, @default_apply_category)

      meta = community.meta |> Map.merge(~m(apply_msg apply_category)a)
      ORM.update_meta(community, meta)
    end
  end

  def approve_community_apply(id) do
    # TODO: create community with thread, category and tags
    with {:ok, community} <- ORM.find(Community, id) do
      ORM.update(community, %{pending: @community_normal})
    end
  end

  def deny_community_apply(id) do
    with {:ok, community} <- ORM.find(Community, id) do
      case community.pending == @community_applying do
        true -> ORM.delete(community)
        false -> {:ok, community}
      end
    end
  end

  @doc """
  update editors_count of a community
  """
  def update_community_count_field(%Community{} = community, user_id, :editors_count, opt) do
    {:ok, editors_count} =
      from(s in CommunityEditor, where: s.community_id == ^community.id)
      |> ORM.count()

    community_meta = if is_nil(community.meta), do: @default_meta, else: community.meta

    editors_ids =
      case opt do
        :inc -> (community_meta.editors_ids ++ [user_id]) |> Enum.uniq()
        :dec -> (community_meta.editors_ids -- [user_id]) |> Enum.uniq()
      end

    meta = community_meta |> Map.put(:editors_ids, editors_ids) |> strip_struct

    community
    |> ORM.update_embed(:meta, meta, %{editors_count: editors_count})
  end

  @doc """
  update article_tags_count of a community
  """
  def update_community_count_field(%Community{} = community, :article_tags_count) do
    {:ok, article_tags_count} =
      from(t in ArticleTag, where: t.community_id == ^community.id)
      |> ORM.count()

    community
    |> Ecto.Changeset.change(%{article_tags_count: article_tags_count})
    |> Repo.update()
  end

  @doc """
  update subscribers_count of a community
  """
  def update_community_count_field(%Community{} = community, user_id, :subscribers_count, opt) do
    {:ok, subscribers_count} =
      from(s in CommunitySubscriber, where: s.community_id == ^community.id) |> ORM.count()

    community_meta = if is_nil(community.meta), do: @default_meta, else: community.meta

    subscribed_user_ids =
      case opt do
        :inc -> (community_meta.subscribed_user_ids ++ [user_id]) |> Enum.uniq()
        :dec -> (community_meta.subscribed_user_ids -- [user_id]) |> Enum.uniq()
      end

    meta = community_meta |> Map.put(:subscribed_user_ids, subscribed_user_ids) |> strip_struct

    community
    |> ORM.update_embed(:meta, meta, %{subscribers_count: subscribers_count})
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
      {:ok, thread_article_count} =
        from(a in info.model,
          join: c in assoc(a, :communities),
          where: a.mark_delete == false and c.id == ^community.id
        )
        |> ORM.count()

      community_meta = if is_nil(community.meta), do: @default_meta, else: community.meta
      meta = Map.put(community_meta, :"#{plural(thread)}_count", thread_article_count)

      community
      |> ORM.update_meta(meta, changes: %{articles_count: recount_articles_count(meta)})
    end
  end

  defp recount_articles_count(meta) do
    @article_threads |> Enum.reduce(0, &(&2 + Map.get(meta, :"#{plural(&1)}_count")))
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

  def community_members(:subscribers, %Community{id: id} = community, filters, %User{meta: meta})
      when not is_nil(id) do
    with {:ok, members} <- community_members(:subscribers, community, filters) do
      user_meta = ensure(meta, @default_user_meta)

      %{entries: entries} = members

      entries =
        Enum.map(entries, fn member ->
          %{member | viewer_has_followed: member.id in user_meta.following_user_ids}
        end)

      %{members | entries: entries} |> done
    end
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
        |> ORM.paginator(page: 1, size: 1)

      {:ok, result.total_count}
    end
  end

  defp do_read_community(raw) do
    with {:ok, community} <- find_community(raw) do
      case community.meta do
        nil ->
          {:ok, community} = ORM.update_meta(community, @default_meta)
          community |> ORM.read(inc: :views)

        _ ->
          community |> ORM.read(inc: :views)
      end
    end
  end

  defp find_community(raw) do
    Community
    |> where([c], c.pending == ^@community_normal)
    |> where([c], c.raw == ^raw or c.aka == ^raw)
    |> Repo.one()
    |> done
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
    |> ORM.paginator(~m(page size)a)
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
    |> ORM.paginator(~m(page size)a)
    |> done()
  end
end
