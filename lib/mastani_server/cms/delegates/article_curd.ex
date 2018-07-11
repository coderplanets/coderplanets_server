defmodule MastaniServer.CMS.Delegate.ArticleCURD do
  import Ecto.Query, warn: false
  import MastaniServer.CMS.Utils.Matcher
  import Helper.Utils, only: [done: 1]
  import ShortMaps

  alias MastaniServer.CMS.{Author, Community}
  alias MastaniServer.{Repo, Accounts, Statistics}
  alias MastaniServer.CMS.Delegate.ArticleOperation
  alias Helper.{ORM, QueryBuilder}

  @doc """
  get paged post / job ...
  """
  def paged_contents(queryable, filter) do
    normal_content_fr = filter |> Map.merge(QueryBuilder.default_article_filters())

    queryable
    |> ORM.find_all(normal_content_fr)
    |> add_pin_contents_ifneed(queryable, filter)
  end

  # only first page need pin contents
  defp add_pin_contents_ifneed(contents, queryable, filter) do
    with {:ok, normal_contents} <- contents,
         true <- 1 == Map.get(normal_contents, :page_number) do
      pin_content_fr = filter |> Map.merge(%{pin: true})
      {:ok, pined_content} = queryable |> ORM.find_all(pin_content_fr)

      case pined_content |> Map.get(:total_entries) do
        0 ->
          contents

        _ ->
          pind_entries = pined_content |> Map.get(:entries)
          normal_entries = normal_contents |> Map.get(:entries)

          normal_count = normal_contents |> Map.get(:total_entries)
          pind_count = pined_content |> Map.get(:total_entries)

          normal_contents
          |> Map.put(:entries, pind_entries ++ normal_entries)
          |> Map.put(:total_entries, pind_count + normal_count)
          |> done
      end
    else
      _error ->
        contents
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
  def create_content(thread, %Accounts.User{id: user_id}, %{community_id: community_id} = attrs) do
    with {:ok, author} <- ensure_author_exists(%Accounts.User{id: user_id}),
         {:ok, action} <- match_action(thread, :community),
         # {:ok, community} <- ORM.find_by(Community, title: attrs.community),
         {:ok, community} <- ORM.find(Community, community_id),
         {:ok, content} <-
           action.target
           |> struct()
           |> action.target.changeset(attrs)
           |> Ecto.Changeset.put_change(:author_id, author.id)
           |> Repo.insert() do
      Statistics.log_publish_action(%Accounts.User{id: user_id})
      ArticleOperation.set_community(thread, content.id, %Community{id: community.id})
    end
  end

  @doc """
  get CMS contents
  post's favorites/stars/comments ...
  ...
  jobs's favorites/stars/comments ...

  with or without page info
  """
  def reaction_users(thread, react, id, %{page: page, size: size} = filters) do
    # when valid_reaction(thread, react) do
    with {:ok, action} <- match_action(thread, react),
         {:ok, where} <- dynamic_where(thread, id) do
      # common_filter(action.reactor)
      action.reactor
      |> where(^where)
      |> QueryBuilder.load_inner_users(filters)
      |> ORM.paginater(~m(page size)a)
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
