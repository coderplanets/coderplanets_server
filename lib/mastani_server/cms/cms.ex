defmodule MastaniServer.CMS do
  @moduledoc """
  this module defined basic method to handle [CMS] content [CURD] ..
  [CMS]: post, job, ...
  [CURD]: create, update, delete ...
  """
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]

  # import MastaniServer.CMS.Logic.CommentReaction
  alias MastaniServer.CMS.Delegate.{
    CommentReaction,
    CommentCURD,
    CommunityCURD,
    Passport,
    CommunityOperation,
    ArticleOperation
  }

  alias MastaniServer.CMS.{
    Author,
    Thread,
    CommunityThread,
    Tag,
    Community
  }

  alias MastaniServer.{Repo, Accounts}
  alias Helper.QueryBuilder
  alias Helper.ORM

  defdelegate create_community(attrs), to: CommunityCURD

  @doc """
  set a community editor
  """
  defdelegate add_editor(user_id, community_id, title), to: CommunityCURD
  defdelegate update_editor(user_id, community_id, title), to: CommunityCURD
  defdelegate delete_editor(user_id, community_id), to: CommunityCURD

  def create_thread(attrs), do: Thread |> ORM.create(attrs)

  def add_thread_to_community(attrs) do
    with {:ok, community_thread} <- CommunityThread |> ORM.create(attrs) do
      Community |> ORM.find(community_thread.community_id)
    end
  end

  @doc """
  create a Tag base on type: post / tuts / videos ...
  """
  def create_tag(part, attrs) when valid_part(part) do
    with {:ok, action} <- match_action(part, :tag),
         {:ok, community} <- ORM.find_by(Community, title: attrs.community) do
      attrs = attrs |> Map.merge(%{community_id: community.id})
      action.reactor |> ORM.create(attrs)
    end
  end

  @doc """
  set tag for post / tuts / videos ...
  """
  # check community first
  defdelegate set_tag(community_title, part, part_id, tag_id), to: ArticleOperation
  defdelegate unset_tag(part, part_id, tag_id), to: ArticleOperation

  # TODO: use comunityId
  def get_tags(community, part) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.title == ^community and t.part == ^part)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  defdelegate set_community(part, part_id, community_title), to: ArticleOperation
  defdelegate unset_community(part, part_id, community_title), to: ArticleOperation

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
         {:ok, community} <- ORM.find_by(Community, title: attrs.community),
         {:ok, content} <-
           struct(action.target)
           |> action.target.changeset(attrs)
           # |> action.target.changeset(attrs |> Map.merge(%{author_id: author.id}))
           |> Ecto.Changeset.put_change(:author_id, author.id)
           |> Repo.insert() do
      set_community(part, content.id, %Community{title: community.title})
    end
  end

  @doc """
  Creates a comment for psot, job ...
  """
  # TODO: remove react
  defdelegate create_comment(part, part_id, user_id, body), to: CommentCURD

  @doc """
  Delete the comment and increase all the floor after this comment
  """
  defdelegate delete_comment(part, part_id), to: CommentCURD

  defdelegate list_comments(part, part_id, filters), to: CommentCURD
  defdelegate list_replies(part, comment_id, user_id), to: CommentCURD
  defdelegate reply_comment(part, comment_id, user_id, body), to: CommentCURD

  # can not use spectial: post_comment_id
  # do not pattern match in delegating func, do it on one delegating inside
  # see https://github.com/elixir-lang/elixir/issues/5306
  defdelegate like_comment(part, comment_id, user_id), to: CommentReaction
  defdelegate undo_like_comment(part, comment_id, user_id), to: CommentReaction

  defdelegate dislike_comment(part, comment_id, user_id), to: CommentReaction
  defdelegate undo_dislike_comment(part, comment_id, user_id), to: CommentReaction

  @doc """
  subscribe a community. (ONLY community, post etc use watch )
  """
  defdelegate subscribe_community(user_id, community_id), to: CommunityOperation
  defdelegate unsubscribe_community(user_id, community_id), to: CommunityOperation

  # include :editors and :subscribers
  defdelegate community_members(type, community_id, filters), to: CommunityCURD

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

  @doc """
  favorite / star / watch CMS contents like post / tuts / video ...
  """
  # TODO: def reaction(part, react, part_id, %Accounts.User{id: user_id}) when valid_reaction(part, react) do
  def reaction(part, react, part_id, %Accounts.User{id: user_id})
      when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- ORM.find(action.target, part_id),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      attrs = Map.put(%{}, "user_id", user.id) |> Map.put("#{part}_id", content.id)
      action.reactor |> ORM.create(attrs)
    end
  end

  @doc """
  unfavorite / unstar / unwatch CMS contents like post / tuts / video ...
  """
  def undo_reaction(part, react, part_id, user_id) when valid_reaction(part, react) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- ORM.find(action.target, part_id) do
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
    ORM.find_by(Author, user_id: changeset.data.user_id)
  end

  # pasport staff
  defdelegate stamp_passport(user_id, rules), to: Passport
  defdelegate erase_passport(user, rules), to: Passport
  defdelegate get_passport(user), to: Passport
  defdelegate list_passports(community, key), to: Passport
end
