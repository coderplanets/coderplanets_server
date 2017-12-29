defmodule MastaniServer.CMS do
  @moduledoc """
  The CMS context.
  """

  import Ecto.Query, warn: false

  alias MastaniServer.CMS.{Post, Author}
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

  def ensure_author_exists(%Accounts.User{} = user) do
    # unique_constraint: avoid race conditions
    # foreign_key_constraint: check user_id exsit
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

  @doc """
  Gets a single post.

  Raises nil if the Post does not exist.

  ## Examples

  iex> get_post!(123)
  %Post{}

  iex> get_post(456)
  ** nil
  """
  def get_post(id), do: Repo.get(Post, id)

  def find_post(id) do
    case get_post(id) do
      nil ->
        {:error, "post id #{id} not found."}

      post ->
        {:ok, post}
    end
  end

  def star_post(post_id, user_id) do
    with {:ok, post} <- find_post(post_id),
         {:ok, user} <- Accounts.find_user(user_id) do
      # IO.inspect(post, label: 'start_post post')
      # IO.inspect(user, label: 'start_post user')
      post
      |> Repo.preload(:starredUsers)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:starredUsers, [user])
      |> Repo.update()
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
  Deletes a Post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
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
end
