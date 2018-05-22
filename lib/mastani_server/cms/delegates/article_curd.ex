defmodule MastaniServer.CMS.Delegate.ArticleCURD do
  import Ecto.Query, warn: false
  import MastaniServer.CMS.Utils.Matcher
  import Helper.Utils, only: [done: 1]

  alias MastaniServer.CMS.{Author, Community}
  alias MastaniServer.{Repo, Accounts}
  alias MastaniServer.CMS.Delegate.ArticleOperation
  alias Helper.{ORM, QueryBuilder}

  @doc """
  Creates a content(post/job ...), and set community.

  ## Examples

  iex> create_post(%{field: value})
  {:ok, %Post{}}

  iex> create_post(%{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def create_content(part, %Author{user_id: author_id}, attrs \\ %{}) do
    with {:ok, author} <- ensure_author_exists(%Accounts.User{id: author_id}),
         {:ok, action} <- match_action(part, :community),
         {:ok, community} <- ORM.find_by(Community, title: attrs.community),
         {:ok, content} <-
           struct(action.target)
           |> action.target.changeset(attrs)
           # |> action.target.changeset(attrs |> Map.merge(%{author_id: author.id}))
           |> Ecto.Changeset.put_change(:author_id, author.id)
           |> Repo.insert() do
      ArticleOperation.set_community(part, content.id, %Community{title: community.title})
    end
  end

  @doc """
  get CMS contents
  post's favorites/stars/comments ...
  ...
  jobs's favorites/stars/comments ...

  with or without page info
  """
  def reaction_users(part, react, id, %{page: page, size: size} = filters) do
    # when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, where} <- dynamic_where(part, id) do
      # common_filter(action.reactor)
      action.reactor
      |> where(^where)
      |> QueryBuilder.load_inner_users(filters)
      |> ORM.paginater(page: page, size: size)
      |> done()
    end
  end

  def ensure_author_exists(%Accounts.User{} = user) do
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
    ORM.find_by(Author, user_id: changeset.data.user_id)
  end
end
