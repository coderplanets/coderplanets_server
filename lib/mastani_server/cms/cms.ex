defmodule MastaniServer.CMS do
  @moduledoc """
  The CMS context.
  """

  import Ecto.Query, warn: false

  alias MastaniServer.CMS.{Post, Author, PostFavorite, PostStar, PostComment, Tag, Community}
  alias MastaniServer.{Repo, Accounts}
  alias MastaniServer.Utils.Helper

  defp match_action(:post, :self), do: {:ok, %{target: Post, reactor: Post, preload: :author}}

  defp match_action(:post, :favorite),
    do: {:ok, %{target: Post, reactor: PostFavorite, preload: :user, preload_right: :post}}

  defp match_action(:post, :star), do: {:ok, %{target: Post, reactor: PostStar, preload: :user}}

  # defp match_action(:post, :tag), do: {:ok, %{target: Post, reactor: PostTag}}
  defp match_action(:post, :tag), do: {:ok, %{target: Post, reactor: Tag}}

  defp match_action(:post, :comment),
    do: {:ok, %{target: Post, reactor: PostComment, preload: :author}}

  @support_part [:post, :video, :job]
  @support_react [:favorite, :star, :watch, :comment, :tag, :self]

  defguardp valid_part(part) when part in @support_part

  defguardp valid_reaction(part, react)
            when valid_part(part) and react in @support_react

  # defguardp valid_pagi(page, size)
  # when is_integer(page) and page > 0 and is_integer(size) and size > 0

  @doc """
  get the author info for CMS.conent
  """
  def load_author(%Author{} = author) do
    with {:ok, result} <- Helper.find(Author, author.id, preload: :user) do
      {:ok, result.user}
    end
  end

  def create_community(attrs) do
    with {:ok, user} <- Helper.find(Accounts.User, attrs.user_id) do
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

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_post(%Author{} = author, attrs \\ %{}) do
    case ensure_author_exists(%Accounts.User{id: author.user_id}) do
      {:ok, author} ->
        %Post{}
        |> Post.changeset(attrs)
        |> Ecto.Changeset.put_change(:author_id, author.id)
        |> Repo.insert()

      {:error, reason} ->
        {:error, reason}
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
  def contents(part, react, filters) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react) do
      try do
        %{page: page, size: size} = filters
        filters = filters |> Map.delete(:page) |> Map.delete(:size)

        result =
          action.target |> Helper.filter_pack(filters)
          |> Repo.paginate(page: page, page_size: size)

        {:ok, result}
      rescue
        _ in MatchError ->
          query = action.target |> Helper.filter_pack(filters)
          {:ok, Repo.all(query)}
      end
    end
  end

  @doc """
  return part's star/favorite/watch .. count

  """
  def reaction_users_count(part, react, part_id) when valid_reaction(part, react) do
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
  get CMS contents
  post's favorites/stars/comments ...
  ...
  jobs's favorites/stars/comments ...

  with or without page info
  """

  def reaction_users(part, react, part_id, filters) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- Helper.find(action.target, part_id) do
      where =
        case part do
          :post -> dynamic([p], p.post_id == ^content.id)
          :meetup -> dynamic([p], p.meetup_id == ^content.id)
        end

      try do
        %{page: page, size: size} = filters
        filters = filters |> Map.delete(:page) |> Map.delete(:size)
        get_reaction_users_with_page(action, where, filters, page, size)
      rescue
        _ in MatchError ->
          get_reaction_users_without_page(action, react, where, filters)
      end
    end
  end

  defp get_reaction_users_without_page(action, react, where, filters) do
    query =
      action.reactor
      |> where(^where)
      |> Helper.filter_pack(filters)
      |> preload(^action.preload)

    result = Repo.all(query)

    case react do
      :comment -> {:ok, result}
      _ -> {:ok, result |> Enum.map(& &1.user)}
    end
  end

  def get_reaction_users_with_page(action, where, filters, page, size) do
    page =
      action.reactor
      |> where(^where)
      |> Helper.filter_pack(filters)
      |> preload(:user)
      |> Repo.paginate(page: page, page_size: size)

    {:ok, %{
      entries: Enum.map(page.entries, & &1.user),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_count: page.total_entries
    }}
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
