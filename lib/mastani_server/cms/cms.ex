defmodule MastaniServer.CMSValidator do
  # TODO: move it to helper
  @support_part [:post, :video, :job]
  @support_react [:favorite, :star, :watch, :comment, :tag, :self]

  @page_size_max 30

  def page_size_boundary, do: @page_size_max

  defguard invalid_page_size(size) when size > @page_size_max or size <= 0

  defguard valid_part(part) when part in @support_part

  defguard valid_reaction(part, react)
           when valid_part(part) and react in @support_react
end

defmodule MastaniServer.CMSMatcher do
  import Ecto.Query, warn: false
  alias MastaniServer.CMS.{Post, PostFavorite, PostStar, PostComment, Tag, Community}

  def match_action(:post, :self), do: {:ok, %{target: Post, reactor: Post, preload: :author}}

  def match_action(:post, :favorite),
    do: {:ok, %{target: Post, reactor: PostFavorite, preload: :user, preload_right: :post}}

  def match_action(:post, :star), do: {:ok, %{target: Post, reactor: PostStar, preload: :user}}

  # defp match_action(:post, :tag), do: {:ok, %{target: Post, reactor: PostTag}}
  def match_action(:post, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  def match_action(:post, :community), do: {:ok, %{target: Post, reactor: Community}}

  def match_action(:post, :comment),
    do: {:ok, %{target: Post, reactor: PostComment, preload: :author}}

  def dynamic_where(part, id) do
    case part do
      :post ->
        {:ok, dynamic([p], p.post_id == ^id)}

      :job ->
        {:ok, dynamic([p], p.job_id == ^id)}

      :meetup ->
        {:ok, dynamic([p], p.meetup_id == ^id)}

      _ ->
        {:error, 'where is not match'}
    end
  end
end

defmodule MastaniServer.CMS do
  import MastaniServer.CMSValidator
  import MastaniServer.CMSMatcher
  import Absinthe.Resolution.Helpers

  @moduledoc """
  The CMS context.
  """

  import Ecto.Query, warn: false

  alias MastaniServer.CMS.{Post, Author, Tag, Community, PostComment, PostFavorite}
  alias MastaniServer.{Repo, Accounts}
  alias MastaniServer.Utils.Helper

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(Author, _args) do
    # you cannot use preload with select together
    # https://stackoverflow.com/questions/43010352/ecto-select-relations-from-preload
    # see also
    # https://github.com/elixir-ecto/ecto/issues/1145
    from(a in Author, join: u in assoc(a, :user), select: u)
  end

  def query({"posts_comments", PostComment}, args) do
    case Map.has_key?(args, :filter) do
      true -> PostComment |> Helper.filter_pack(args.filter)
      _ -> PostComment
    end
  end

  def query({"posts_favorites", PostFavorite}, %{
        arg_viewer_reacted: _,
        current_user: current_user
      }) do
    PostFavorite
    |> where([f], f.user_id == ^current_user.id)
  end

  def query({"posts_favorites", PostFavorite}, %{arg_count: _}) do
    # IO.inspect(current_user, label: 'context user--> ')
    PostFavorite
    |> group_by([f], f.post_id)
    |> select([f], count(f.id))
  end

  def query({"posts_favorites", PostFavorite}, args) do
    # TODO: Repo.paginate(page: page, page_size: size)
    # TODO: default filter
    case Map.has_key?(args, :filter) do
      true ->
        PostFavorite
        |> join(:inner, [f], u in assoc(f, :user))
        |> select([f, u], u)
        |> Helper.filter_pack(args.filter)

      _ ->
        PostFavorite
    end

    # IO.inspect(args, label: 'args')
    # IO.inspect(PostFavorite, label: 'PostFavorite')
    # from(f in PostFavorite, join: u in assoc(f, :user), select: u) |> Helper.filter_pack(args.filter)
  end

  def query(queryable, _args) do
    queryable
  end

  @doc """
  get the author info for CMS.conent
  just for compare
  """
  def load_author(%Author{} = author) do
    with {:ok, result} <- Helper.find(Author, author.id, preload: :user) do
      {:ok, result.user}
    end
  end

  def create_community(attrs) do
    with {:ok, user} <- Helper.find(Accounts.User, attrs.user_id) do
      # {:error, "custom error."}
      %Community{}
      |> Community.changeset(attrs |> Map.merge(%{user_id: user.id}))
      |> Repo.insert()
    end
  end

  def delete_community(id) do
    with {:ok, community} <- Helper.find(Community, id) do
      Repo.delete(community)
    end
  end

  @doc """
  create a Tag base on type: post / tuts / videos ...
  """
  def create_tag(part, attrs) when valid_part(part) do
    # TODO: find user
    with {:ok, action} <- match_action(part, :tag),
         {:ok, community} <- Repo.get_by(Community, title: attrs.community) |> Helper.one_resp() do
      struct(action.reactor)
      |> action.reactor.changeset(attrs |> Map.merge(%{community_id: community.id}))
      |> Repo.insert()
    end
  end

  @doc """
  set tag for post / tuts / videos ...
  """
  # check community first
  def set_tag(part, part_id, tag_id) when valid_part(part) do
    with {:ok, action} <- match_action(part, :tag),
         {:ok, content} <- Helper.find(action.target, part_id, preload: :tags),
         {:ok, tag} <- Helper.find(action.reactor, tag_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, content.tags ++ [tag])
      |> Repo.update()
    end
  end

  # TODO: check community exsit
  def get_tags(community, part) do
    query =
      Tag
      |> join(:inner, [t], c in assoc(t, :community))
      |> where([t, c], c.title == ^community and t.part == ^part)
      |> distinct([t], t.title)

    # |> select([t])
    # IO.inspect Repo.all(query), label: "get tags"
    {:ok, Repo.all(query)}
  end

  def set_community(part, part_id, community_id) when valid_part(part) do
    with {:ok, action} <- match_action(part, :community),
         {:ok, content} <- Helper.find(action.target, part_id, preload: :communities),
         {:ok, community} <- Helper.find(action.reactor, community_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:communities, content.communities ++ [community])
      |> Repo.update()
    end
  end

  @doc """
  Creates a content(post/job ...), and set community.

  ## Examples

  iex> create_post(%{field: value})
  {:ok, %Post{}}

  iex> create_post(%{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def create_content(part, %Author{} = author, attrs \\ %{}) do
    with {:ok, author} <- ensure_author_exists(%Accounts.User{id: author.user_id}),
         {:ok, action} <- match_action(part, :community),
         {:ok, community} <- Repo.get_by(Community, title: attrs.community) |> Helper.one_resp(),
         # {:ok, community} <- Helper.find(action.target, 1),
         {:ok, content} <-
           struct(action.target)
           |> Post.changeset(attrs)
           |> Ecto.Changeset.put_change(:author_id, author.id)
           |> Repo.insert() do
      set_community(part, content.id, community.id)
    end
  end

  def create_comment(part, react, part_id, user_id, body) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- Helper.find(action.target, part_id),
         {:ok, user} <- Accounts.find_user(user_id) do
      struct(action.reactor)
      |> action.reactor.changeset(%{post_id: content.id, author_id: user.id, body: body})
      |> Repo.insert()
    end
  end

  defp inc_views_count(content, target) do
    {1, [result]} =
      Repo.update_all(
        from(p in target, where: p.id == ^content.id),
        [inc: [views: 1]],
        returning: [:views]
      )

    put_in(content.views, result.views)
  end

  @doc """
  get one CMS contents (post, tut, video, job ...)
  """
  def one_conent(part, react, id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, result} <- Helper.find(action.target, id) do
      {:ok, result |> inc_views_count(action.target)}
    end
  end

  def one_conent(part, _, _), do: {:error, "cms do not support [#{part}] type"}

  @doc """
  get CMS contents (posts, tuts, videos, jobs ...) with or without page info
  """
  def contents(_, _, %{size: size}) when invalid_page_size(size),
    do:
      {:error,
       "invalid size request: size should less than #{page_size_boundary()} and more than 0"}

  def contents(_, _, %{first: size}) when invalid_page_size(size),
    do:
      {:error,
       "invalid size request: size should less than #{page_size_boundary()} and more than 0"}

  # TODO: try default size
  def contents(part, react, %{page: page, size: size} = filters)
      when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react) do
      filters = filters |> Map.delete(:page) |> Map.delete(:size)

      result =
        action.target
        |> Helper.filter_pack(filters)
        |> Repo.paginate(page: page, page_size: size)

      {:ok, result}
    end
  end

  def contents(part, react, filters) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react) do
      query = action.target |> Helper.filter_pack(filters)
      {:ok, Repo.all(query)}
    end
  end

  def contents(part, react, _), do: {:error, "cms do not support [#{react}] on [#{part}]"}

  @doc """
  get CMS contents
  post's favorites/stars/comments ...
  ...
  jobs's favorites/stars/comments ...

  with or without page info
  """
  def reaction_users(_, _, _, %{size: size}) when invalid_page_size(size),
    do:
      {:error,
       "invalid size request: size should less than #{page_size_boundary()} and more than 0"}

  def reaction_users(_, _, _, %{first: size}) when invalid_page_size(size),
    do:
      {:error,
       "invalid size request: size should less than #{page_size_boundary()} and more than 0"}

  def reaction_users(part, react, root, %{page: page, size: size} = filters)
      when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, where} <- dynamic_where(part, root.id) do
      # filters = filters |> Map.delete(:page) |> Map.delete(:size)
      page =
        action.reactor
        |> where(^where)
        |> Helper.filter_pack(filters)
        |> preload(:user)
        |> Repo.paginate(page: page, page_size: size)

      {:ok,
       %{
         entries: Enum.map(page.entries, & &1.user),
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_count: page.total_entries
       }}
    end
  end

  def reaction_users(part, react, root, filters) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, where} <- dynamic_where(part, root.id) do
      result =
        action.reactor
        |> where(^where)
        |> Helper.filter_pack(filters)
        |> preload(^action.preload)
        |> Repo.all()
        |> Enum.map(& &1.user)

      {:ok, result}
    end
  end

  def reaction_members(loader, association, root, args) do
    loader
    |> Dataloader.load(MastaniServer.CMS, association, root)
    |> on_load(fn loader ->
      ids =
        loader
        |> Dataloader.get(MastaniServer.CMS, association, root)
        # <- may have performence issue when very big
        |> Enum.map(& &1.id)

      users =
        MastaniServer.CMS.PostFavorite
        |> where([f], f.id in ^ids)
        |> Helper.filter_pack(args.filter)
        |> preload(:user)
        |> Repo.all()
        |> Enum.map(& &1.user)

      # |> IO.inspect(label: 'fucking2')

      {:ok, users}
    end)
  end

  @doc """
  TODO: remove
  loader is the dataloader loader which is in context
  association is must exist in the model
  like post's favorites:
  ----------
  has_many(:favorites, {"posts_favorites", PostFavorite})
  """
  def reaction_count_loader(loader, association, root) do
    # IO.inspect(Map.has_key?(root, association), label: 'do root check')
    # this check is not nessery, just in case
    case Map.has_key?(root, association) do
      true ->
        loader
        |> Dataloader.load(MastaniServer.CMS, association, root)
        |> on_load(fn loader ->
          result =
            loader
            |> Dataloader.get(MastaniServer.CMS, association, root)
            |> length

          {:ok, result}
        end)

      _ ->
        {:error, "reaction_count root and association not match"}
    end
  end

  @doc """
  return part's star/favorite/watch .. count
  """
  def reaction_count(part, react, part_id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react) do
      assoc_field = String.to_atom("#{react}s")

      query =
        action.target
        |> join(:left, [p], s in assoc(p, ^assoc_field))
        |> where([p, s], s.post_id == ^part_id)
        |> select([s], count(s.id))

      {:ok, Repo.one(query)}
    end
  end

  @doc """
  check the if the viewer has reacted to content
  find post_id and user_id in PostFavorite
  ...
  jobs's favorites/stars/comments ...

  with or without page info
  """
  # loader, association, root
  def is_viewer_reacted(loader, cur_user, association, root) do
    IO.inspect(root, label: 'root is')

    loader
    |> Dataloader.load(MastaniServer.CMS, association, root)
    |> on_load(fn loader ->
      result =
        loader
        |> Dataloader.get(MastaniServer.CMS, association, root)
        |> IO.inspect()

      {:ok, true}
    end)
  end

  def viewer_has_reacted(part, react, part_id, user_id) when valid_reaction(part, react) do
    # find post_id and user_id in PostFavorite
    with {:ok, action} <- match_action(part, react),
         {:ok, where} <- dynamic_where(part, part_id) do
      action.reactor
      |> where(^where)
      |> where([a], a.user_id == ^user_id)
      |> Repo.one()
      |> case do
        nil ->
          {:ok, false}

        _ ->
          {:ok, true}
      end
    end
  end

  def delete_content(part, react, id, %Accounts.User{} = current_user) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- Helper.find(action.reactor, id, preload: action.preload) do
      content_author_id =
        case react do
          :comment -> content.author.id
          _ -> content.author.user_id
        end

      case current_user.id == content_author_id do
        true -> Repo.delete(content)
        _ -> Helper.access_deny(:owner_required)
      end
    end
  end

  @doc """
  favorite / star / watch CMS contents like post / tuts / video ...
  """
  def reaction(part, react, part_id, user_id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- Helper.find(action.target, part_id),
         {:ok, user} <- Accounts.find_user(user_id) do
      params = Map.put(%{}, "user_id", user.id) |> Map.put("#{part}_id", content.id)

      struct(action.reactor)
      |> action.reactor.changeset(params)
      |> Repo.insert()
      |> case do
        {:ok, _} -> {:ok, content}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  def reaction(part, react, _, _), do: {:error, "cms do not support [#{react}] on [#{part}]"}

  @doc """
  unfavorite / unstar / unwatch CMS contents like post / tuts / video ...
  """
  def undo_reaction(part, react, part_id, user_id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- Helper.find(action.target, part_id) do
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

  def undo_reaction(part, react, _, _),
    do: {:error, "cms do not support [un#{react}] on [#{part}]"}

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a single author.

  Raises `Ecto.NoResultsError` if the Author does not exist.

  ## Examples

      iex> get_author!(123)
      %Author{}

      iex> get_author!(456)
      ** (Ecto.NoResultsError)

  """
  def get_author!(id), do: Repo.get!(Author, id)

  @doc """
  Creates a author.

  ## Examples

      iex> create_author(%{field: value})
      {:ok, %Author{}}

      iex> create_author(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_author(attrs \\ %{}) do
    %Author{}
    |> Author.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a author.

  ## Examples

      iex> update_author(author, %{field: new_value})
      {:ok, %Author{}}

      iex> update_author(author, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_author(%Author{} = author, attrs) do
    author
    |> Author.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Author.

  ## Examples

      iex> delete_author(author)
      {:ok, %Author{}}

      iex> delete_author(author)
      {:error, %Ecto.Changeset{}}

  """
  def delete_author(%Author{} = author) do
    Repo.delete(author)
  end

  defp ensure_author_exists(%Accounts.User{} = user) do
    # unique_constraint: avoid race conditions, make sure user_id unique
    # foreign_key_constraint: check foreign key: user_id exsit or not
    # see alos no_assoc_constraint in https://hexdocs.pm/ecto/Ecto.Changeset.html
    %Author{user_id: user.id}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.unique_constraint(:user_id)
    |> Ecto.Changeset.foreign_key_constraint(:user_id)
    |> Repo.insert()
    |> handle_existing_author()
  end

  defp handle_existing_author({:ok, author}), do: {:ok, author}

  defp handle_existing_author({:error, changeset}) do
    case Repo.get_by(Author, user_id: changeset.data.user_id) do
      nil ->
        {:error, "user is not exsit"}

      user ->
        {:ok, user}
    end
  end
end
