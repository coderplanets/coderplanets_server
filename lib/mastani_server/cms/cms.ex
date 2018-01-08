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

  def star_content(type, content_id, user_id) do
    with {:ok, content} <- which_content(type),
         {:ok, target} <- find_content(content, content_id),
         {:ok, user} <- Accounts.find_user(user_id) do
      target_with_starredUsers = target |> Repo.preload(:starredUsers)

      target_with_starredUsers
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:starredUsers, target_with_starredUsers.starredUsers ++ [user])
      |> Repo.update()
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

  defp which_content(:post), do: {:ok, Post}
  defp which_content(_), do: {:error, "cms do not support this content"}

  defp find_content(content, id) do
    case Repo.get(content, id) do
      nil ->
        {:error, "#{content} id #{id} not found."}

      content ->
        {:ok, content}
    end
  end
end
