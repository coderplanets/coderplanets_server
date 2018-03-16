defmodule MastaniServer.CMS do
  @moduledoc """
  this module defined basic method to handle [CMS] content [CURD] ..
  [CMS]: post, job, ...
  [CURD]: create, update, delete ...
  """
  import MastaniServer.CMSMisc
  import Ecto.Query, warn: false
  import MastaniServer.Utils.Helper

  alias MastaniServer.CMS.{Post, Author, Tag, Community, PostComment, PostFavorite, PostStar}
  alias MastaniServer.{Repo, Accounts}
  alias MastaniServer.Utils.QueryPuzzle

  def data(), do: Dataloader.Ecto.new(Repo, query: &query/2)

  def query(Author, _args) do
    # you cannot use preload with select together
    # https://stackoverflow.com/questions/43010352/ecto-select-relations-from-preload
    # see also
    # https://github.com/elixir-ecto/ecto/issues/1145
    from(a in Author, join: u in assoc(a, :user), select: u)
  end

  def query({"posts_comments", PostComment}, %{filter: filter}) do
    PostComment |> QueryPuzzle.filter_pack(filter)
  end

  @doc """
  handle query:
  1. bacic filter of pagi,when,sort ...
  2. count of the reactions
  3. check is viewer reacted
  """
  def query({"posts_favorites", PostFavorite}, args) do
    PostFavorite |> QueryPuzzle.reactions_hanlder(args)
  end

  def query({"posts_stars", PostStar}, args) do
    PostStar |> QueryPuzzle.reactions_hanlder(args)
  end

  def query(queryable, _args) do
    # IO.inspect(queryable, label: 'default queryable')
    queryable
  end

  def create_community(attrs) do
    with {:ok, user} <- find(Accounts.User, attrs.user_id) do
      %Community{}
      # |> Community.changeset(attrs |> Map.merge(%{user_id2: user.id}))
      |> Community.changeset(attrs)
      |> Repo.insert()
    end
  end

  def delete_community(id) do
    with {:ok, community} <- find(Community, id) do
      Repo.delete(community)
    end
  end

  @doc """
  create a Tag base on type: post / tuts / videos ...
  """
  def create_tag(part, attrs) when valid_part(part) do
    # TODO: find user
    with {:ok, action} <- match_action(part, :tag),
         {:ok, community} <- find_by(Community, title: attrs.community) do
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
         {:ok, content} <- find(action.target, part_id, preload: :tags),
         {:ok, tag} <- find(action.reactor, tag_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, content.tags ++ [tag])
      |> Repo.update()
    end
  end

  # TODO: check community exsit
  def get_tags(community, part) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.title == ^community and t.part == ^part)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  def set_community(part, part_id, community_id) when valid_part(part) do
    with {:ok, action} <- match_action(part, :community),
         {:ok, content} <- find(action.target, part_id, preload: :communities),
         {:ok, community} <- find(action.reactor, community_id) do
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
         {:ok, community} <- find_by(Community, title: attrs.community),
         {:ok, content} <-
           struct(action.target)
           |> Post.changeset(attrs)
           |> Ecto.Changeset.put_change(:author_id, author.id)
           |> Repo.insert() do
      set_community(part, content.id, community.id)
    end
  end

  @doc """
  Creates a comment for psot, job ...
  """
  def create_comment(part, react, part_id, user_id, body) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- find(action.target, part_id),
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
         {:ok, result} <- find(action.target, id) do
      result |> inc_views_count(action.target) |> done()
    end
  end

  def one_conent(part, _, _), do: {:error, "cms do not support [#{part}] type"}

  @doc """
  get CMS contents (posts, tuts, videos, jobs ...) with or without page info
  """

  # TODO: change it to invalid guard..
  def contents(part, react, %{page: page, size: size} = filters)
      when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react) do
      filters = filters |> Map.delete(:page) |> Map.delete(:size)

      action.target
      |> QueryPuzzle.filter_pack(filters)
      |> paginater(page: page, size: size)
    end
  end

  def contents(part, react, filters) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react) do
      # query = action.target |> QueryPuzzle.filter_pack(filters)
      # {:ok, Repo.all(query)}
      action.target |> QueryPuzzle.filter_pack(filters) |> Repo.all() |> done()
    end
  end

  # def contents(part, react, _), do: {:error, "cms do not support [#{react}] on [#{part}]"}
  @doc """
  get CMS contents
  post's favorites/stars/comments ...
  ...
  jobs's favorites/stars/comments ...

  with or without page info
  """
  def reaction_users(part, react, id, %{page: page, size: size} = filters)
      when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, where} <- dynamic_where(part, id) do
      # common_filter(action.reactor)
      action.reactor
      |> where(^where)
      |> QueryPuzzle.reaction_members(filters)
      |> paginater(page: page, size: size)
    end
  end

  @doc """
  return part's star/favorite/watch .. count
  """
  def reaction_count(part, react, part_id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react) do
      assoc_field = String.to_atom("#{react}s")

      action.target
      |> join(:left, [p], s in assoc(p, ^assoc_field))
      |> where([p, s], s.post_id == ^part_id)
      |> select([s], count(s.id))
      |> Repo.one()
      |> done()
    end
  end

  @doc """
  check the if the viewer has reacted to content
  find post_id and user_id in PostFavorite
  ...
  jobs's favorites/stars/comments ...

  with or without page info
  """
  def viewer_has_reacted(part, react, part_id, user_id) when valid_reaction(part, react) do
    # find post_id and user_id in PostFavorite
    with {:ok, action} <- match_action(part, react),
         {:ok, where} <- dynamic_where(part, part_id) do
      action.reactor
      |> where(^where)
      |> where([a], a.user_id == ^user_id)
      |> Repo.one()
      |> done(:boolean)
    end
  end

  def update_content(part, react, part_id, %Accounts.User{} = current_user, attrs \\ %{}) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- find(action.target, part_id, preload: action.preload) do
      content_author_id =
        case react do
          :comment -> content.author.id
          _ -> content.author.user_id
        end

      case current_user.id == content_author_id do
        true ->
          content
          |> action.target.changeset(attrs)
          |> Repo.update()

        _ ->
          operation_deny(:owner_required)
      end
    end
  end

  def delete_content(content) do
    Repo.delete(content)
  end

  def delete_content(part, react, id, %Accounts.User{} = current_user) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- find(action.reactor, id, preload: action.preload) do
      # TODO: move check logic to Middleware
      content_author_id =
        case react do
          :comment -> content.author.id
          _ -> content.author.user_id
        end

      case current_user.id == content_author_id do
        true -> Repo.delete(content)
        _ -> operation_deny(:owner_required)
      end
    end
  end

  @doc """
  favorite / star / watch CMS contents like post / tuts / video ...
  """
  def reaction(part, react, part_id, user_id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- find(action.target, part_id),
         {:ok, user} <- Accounts.find_user(user_id) do
      params = Map.put(%{}, "user_id", user.id) |> Map.put("#{part}_id", content.id)

      struct(action.reactor)
      |> action.reactor.changeset(params)
      |> Repo.insert()
    end
  end

  # def reaction(part, react, _, _), do: {:error, "cms do not support [#{react}] on [#{part}]"}

  @doc """
  unfavorite / unstar / unwatch CMS contents like post / tuts / video ...
  """
  def undo_reaction(part, react, part_id, user_id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- find(action.target, part_id) do
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

  # def undo_reaction(part, react, _, _),
  # do: {:error, "cms do not support [un#{react}] on [#{part}]"}

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
    find_by(Author, user_id: changeset.data.user_id)
  end
end
