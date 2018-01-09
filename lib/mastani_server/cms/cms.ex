defmodule MastaniServer.CMS do
  @moduledoc """
  The CMS context.
  """

  import Ecto.Query, warn: false
  # import Ecto.Query, only: [from: 2]

  alias MastaniServer.CMS.{Post, Author, Comment, PostFavorite, PostStar}
  alias MastaniServer.{Repo, Accounts}

  @doc """
  Returns the list of cms_posts.

  ## Examples

      iex> list_cms_posts()
      [%Post{}, ...]

  """
  def list_cms_posts do
    Repo.all(Post)
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  # def create_content(%Author{} = author, attrs \\ %{}), do ...

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

  # join table is fine, see https://github.com/elixir-ecto/ecto/issues/2366
  # use reaction to handle starredUsers watchedUsers favortedUsers
  defp which_content(:post), do: {:ok, Post}
  defp which_content(:comment), do: {:ok, Comment}
  defp which_content(_), do: {:error, "cms do not support this content"}

  defp match_action(:post, :favorite), do: {:ok, %{target: Post, reactor: PostFavorite}}
  defp match_action(:post, :star), do: {:ok, %{target: Post, reactor: PostStar}}

  defguardp valid_reaction(part, react)
            when part in [:post, :job] and react in [:favorite, :star, :watch]

  defguardp valid_pagi(page, size)
            when is_integer(page) and page > 0 and is_integer(size) and size > 0

  # favorite, star, watch
  # ... with ...
  # post, job, meetup, video ...
  # def add_react ....
  def do_reaction(part, react, part_id, user_id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- find_content(action.target, part_id),
         {:ok, user} <- Accounts.find_user(user_id) do
      params = Map.put(%{}, "user_id", user.id) |> Map.put("#{part}_id", content.id)

      struct(action.reactor)
      |> action.reactor.changeset(params)
      |> Repo.insert()
      |> case do
        {:ok, _} -> {:ok, content}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def do_reaction(part, react, _, _), do: {:error, "cms do not support [#{react}] on [#{part}]"}

  def undo_reaction(part, react, part_id, user_id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- find_content(action.target, part_id) do
      the_user = dynamic([u], u.user_id == ^user_id)

      where =
        case part do
          :post -> dynamic([p], p.post_id == ^content.id and ^the_user)
          :star -> dynamic([p], p.star_id == ^content.id and ^the_user)
        end

      query = from(f in action.reactor, where: ^where)

      case Repo.one(query) do
        nil -> {:error, "record not found"}
        record -> Repo.delete(record)
      end
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def undo_reaction(part, react, _, _),
    do: {:error, "cms do not support [un#{react}] on [#{part}]"}

  def reaction_users(part, react, part_id, page \\ 1, size \\ 20)

  def reaction_users(part, react, part_id, page, size)
      when valid_reaction(part, react) and valid_pagi(page, size) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- find_content(action.target, part_id) do
      where =
        case part do
          :post -> dynamic([p], p.post_id == ^content.id)
          :star -> dynamic([p], p.star_id == ^content.id)
        end

      page =
        action.reactor
        |> where(^where)
        |> order_by(asc: :inserted_at)
        |> preload(:user)
        |> Repo.paginate(page: page, page_size: size)

      {:ok, %{
        entries: Enum.map(page.entries, & &1.user),
        page_number: page.page_number,
        page_size: page.page_size,
        total_pages: page.total_pages,
        total_count: page.total_entries
      }}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def reaction_users(part, react, _, _, _),
    do: {:error, "cms do not support [#{react}] on [#{part}]"}

  def favorite_users(post_id) do
    # query = from f in PostFavorite, where: f.post_id == ^post_id, select: f.inserted_at
    query =
      from(
        f in PostFavorite,
        where: f.post_id == ^post_id,
        preload: [:user],
        # order_by: [desc: :inserted_at]
        order_by: [asc: :inserted_at]
      )

    {:ok, Repo.all(query) |> Enum.map(& &1.user)}
  end

  def comment_post(post_id, body) do
    # TODO: use Multi to do it
    with {:ok, post} <- find_content(Post, post_id),
         {:ok, comment} <- create_comment(%{body: body}) do
      # ugly hack, see https://elixirforum.com/t/put-assoc-in-many-to-many-crash-the-server/11409/3
      case Repo.insert_all("cms_posts_comments", [%{post_id: post.id, comment_id: comment.id}]) do
        {_, nil} -> {:ok, comment}
      end
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete_content(type, id) do
    with {:ok, content} <- which_content(type),
         {:ok, target} <- find_content(content, id) do
      target |> Repo.delete()
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

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
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{source: %Post{}}

  """
  def change_post(%Post{} = post) do
    Post.changeset(post, %{})
  end

  alias MastaniServer.CMS.Author

  @doc """
  Returns the list of cms_authors.

  ## Examples

      iex> list_cms_authors()
      [%Author{}, ...]

  """
  def list_cms_authors do
    Repo.all(Author)
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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking author changes.

  ## Examples

      iex> change_author(author)
      %Ecto.Changeset{source: %Author{}}

  """
  def change_author(%Author{} = author) do
    Author.changeset(author, %{})
  end

  defp find_content(content, id) do
    case Repo.get(content, id) do
      nil ->
        {:error, "#{content} id #{id} not found."}

      content ->
        {:ok, content}
    end
  end

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{source: %Comment{}}

  """
  def change_comment(%Comment{} = comment) do
    Comment.changeset(comment, %{})
  end

  alias MastaniServer.CMS.PostFavorite

  @doc """
  Returns the list of post_favorites.

  ## Examples

      iex> list_post_favorites()
      [%PostFavorite{}, ...]

  """
  def list_post_favorites do
    Repo.all(PostFavorite)
  end

  @doc """
  Gets a single post_favorite.

  Raises `Ecto.NoResultsError` if the Post favorite does not exist.

  ## Examples

      iex> get_post_favorite!(123)
      %PostFavorite{}

      iex> get_post_favorite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post_favorite!(id), do: Repo.get!(PostFavorite, id)

  @doc """
  Creates a post_favorite.

  ## Examples

      iex> create_post_favorite(%{field: value})
      {:ok, %PostFavorite{}}

      iex> create_post_favorite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post_favorite(attrs \\ %{}) do
    %PostFavorite{}
    |> PostFavorite.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post_favorite.

  ## Examples

      iex> update_post_favorite(post_favorite, %{field: new_value})
      {:ok, %PostFavorite{}}

      iex> update_post_favorite(post_favorite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post_favorite(%PostFavorite{} = post_favorite, attrs) do
    post_favorite
    |> PostFavorite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PostFavorite.

  ## Examples

      iex> delete_post_favorite(post_favorite)
      {:ok, %PostFavorite{}}

      iex> delete_post_favorite(post_favorite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post_favorite(%PostFavorite{} = post_favorite) do
    Repo.delete(post_favorite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post_favorite changes.

  ## Examples

      iex> change_post_favorite(post_favorite)
      %Ecto.Changeset{source: %PostFavorite{}}

  """
  def change_post_favorite(%PostFavorite{} = post_favorite) do
    PostFavorite.changeset(post_favorite, %{})
  end

  alias MastaniServer.CMS.PostStar

  @doc """
  Returns the list of post_stars.

  ## Examples

      iex> list_post_stars()
      [%PostStar{}, ...]

  """
  def list_post_stars do
    Repo.all(PostStar)
  end

  @doc """
  Gets a single post_star.

  Raises `Ecto.NoResultsError` if the Post star does not exist.

  ## Examples

      iex> get_post_star!(123)
      %PostStar{}

      iex> get_post_star!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post_star!(id), do: Repo.get!(PostStar, id)

  @doc """
  Creates a post_star.

  ## Examples

      iex> create_post_star(%{field: value})
      {:ok, %PostStar{}}

      iex> create_post_star(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post_star(attrs \\ %{}) do
    %PostStar{}
    |> PostStar.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post_star.

  ## Examples

      iex> update_post_star(post_star, %{field: new_value})
      {:ok, %PostStar{}}

      iex> update_post_star(post_star, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post_star(%PostStar{} = post_star, attrs) do
    post_star
    |> PostStar.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PostStar.

  ## Examples

      iex> delete_post_star(post_star)
      {:ok, %PostStar{}}

      iex> delete_post_star(post_star)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post_star(%PostStar{} = post_star) do
    Repo.delete(post_star)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post_star changes.

  ## Examples

      iex> change_post_star(post_star)
      %Ecto.Changeset{source: %PostStar{}}

  """
  def change_post_star(%PostStar{} = post_star) do
    PostStar.changeset(post_star, %{})
  end
end
