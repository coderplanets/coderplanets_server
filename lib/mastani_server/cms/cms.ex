defmodule MastaniServer.CMS do
  @moduledoc """
  this module defined basic method to handle [CMS] content [CURD] ..
  [CMS]: post, job, ...
  [CURD]: create, update, delete ...
  """
  import MastaniServer.CMS.Misc
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, deep_merge: 2]
  import ShortMaps

  alias Ecto.Multi

  alias MastaniServer.CMS.{
    Author,
    Thread,
    CommunityThread,
    Tag,
    Community,
    Passport,
    CommunitySubscriber,
    CommunityEditor,
    PostCommentReply
  }

  alias MastaniServer.{Repo, Accounts}
  alias Helper.QueryBuilder
  alias Helper.{ORM, Certification}

  @doc """
  set a community editor
  """
  def add_editor(%Accounts.User{id: user_id}, %Community{id: community_id}, title) do
    Multi.new()
    |> Multi.insert(
      :insert_editor,
      CommunityEditor.changeset(%CommunityEditor{}, ~m(user_id community_id title)a)
    )
    |> Multi.run(:stamp_passport, fn _ ->
      rules = Certification.passport_rules(cms: title)
      stamp_passport(%Accounts.User{id: user_id}, rules)
    end)
    |> Repo.transaction()
    |> add_editor_result()
  end

  def update_editor(%Accounts.User{id: user_id}, %Community{id: community_id}, title) do
    clauses = ~m(user_id community_id)a

    with {:ok, _} <- CommunityEditor |> ORM.update_by(clauses, ~m(title)a) do
      Accounts.User |> ORM.find(user_id)
    end
  end

  def delete_editor(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, _} <- ORM.findby_delete(CommunityEditor, ~m(user_id community_id)a),
         {:ok, _} <- ORM.findby_delete(Passport, ~m(user_id)a) do
      Accounts.User |> ORM.find(user_id)
    end
  end

  defp add_editor_result({:ok, %{insert_editor: editor}}) do
    Accounts.User |> ORM.find(editor.user_id)
  end

  defp add_editor_result({:error, :stamp_passport, _result, _steps}),
    do: {:error, "stamp passport error"}

  defp add_editor_result({:error, :insert_editor, _result, _steps}),
    do: {:error, "insert editor error"}

  def create_community(attrs), do: Community |> ORM.create(attrs)

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
  def set_tag(community_title, part, part_id, tag_id) when valid_part(part) do
    with {:ok, action} <- match_action(part, :tag),
         {:ok, content} <- ORM.find(action.target, part_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      case tag_in_community_part?(community_title, part, tag) do
        true ->
          content
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:tags, content.tags ++ [tag])
          |> Repo.update()

        _ ->
          {:error, "Tag,Community,Part not match"}
      end
    end
  end

  defp tag_in_community_part?(community_title, part, tag) do
    with {:ok, community} <- ORM.find_by(Community, title: community_title) do
      matched_tags =
        Tag
        |> where([t], t.community_id == ^community.id)
        |> where([t], t.part == ^(to_string(part) |> String.upcase()))
        |> Repo.all()

      tag in matched_tags
    end
  end

  def unset_tag(part, part_id, tag_id) when valid_part(part) do
    with {:ok, action} <- match_action(part, :tag),
         {:ok, content} <- ORM.find(action.target, part_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, content.tags -- [tag])
      |> Repo.update()
    end
  end

  # TODO: use comunityId
  def get_tags(community, part) do
    Tag
    |> join(:inner, [t], c in assoc(t, :community))
    |> where([t, c], c.title == ^community and t.part == ^part)
    |> distinct([t], t.title)
    |> Repo.all()
    |> done()
  end

  def set_community(part, part_id, %Community{title: title}) when valid_part(part) do
    with {:ok, action} <- match_action(part, :community),
         {:ok, content} <- ORM.find(action.target, part_id, preload: :communities),
         {:ok, community} <- ORM.find_by(action.reactor, title: title) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:communities, content.communities ++ [community])
      |> Repo.update()
    end
  end

  def unset_community(part, part_id, %Community{title: title}) when valid_part(part) do
    with {:ok, action} <- match_action(part, :community),
         {:ok, content} <- ORM.find(action.target, part_id, preload: :communities),
         {:ok, community} <- ORM.find_by(action.reactor, title: title) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:communities, content.communities -- [community])
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
  def create_comment(part, react, part_id, %Accounts.User{id: user_id}, body) do
    with {:ok, action} <- match_action(part, react),
         {:ok, content} <- ORM.find(action.target, part_id),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      # TODO post_id
      nextFloor =
        action.reactor
        |> where([c], c.post_id == ^content.id and c.author_id == ^user.id)
        |> ORM.next_count()

      # IO.inspect(nextFloor, label: "count -> ")
      attrs = %{post_id: content.id, author_id: user.id, body: body, floor: nextFloor}
      action.reactor |> ORM.create(attrs)
    end
  end

  @doc """
  Delete the comment and increase all the floor after this comment
  """
  def delete_comment(part, part_id) do
    with {:ok, action} <- match_action(part, :comment),
         {:ok, comment} <- ORM.find(action.reactor, part_id) do
      case ORM.delete(comment) do
        {:ok, comment} ->
          Repo.update_all(
            from(p in action.reactor, where: p.id > ^comment.id),
            inc: [floor: -1]
          )

          {:ok, comment}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  def list_comments(part, part_id, %{page: page, size: size} = filters) do
    with {:ok, action} <- match_action(part, :comment) do
      action.reactor
      # TODO: make post_id common
      |> where([c], c.post_id == ^part_id)
      |> QueryBuilder.filter_pack(filters)
      |> ORM.paginater(page: page, size: size)
      |> done()
    end
  end

  def list_replies(part, comment_id, %Accounts.User{id: user_id}) do
    with {:ok, action} <- match_action(part, :comment) do
      action.reactor
      |> where([c], c.author_id == ^user_id)
      |> join(:inner, [c], r in assoc(c, :reply_to))
      |> where([c, r], r.id == ^comment_id)
      |> Repo.all()
      |> done()
    end
  end

  def reply_comment(part, comment_id, %Accounts.User{id: user_id}, body) do
    with {:ok, action} <- match_action(part, :comment),
         {:ok, comment} <- ORM.find(action.reactor, comment_id) do
      attrs = %{post_id: comment.post_id, author_id: user_id, body: body, reply_to: comment}
      # TODO: use Multi task to refactor
      case action.reactor |> ORM.create(attrs) do
        {:ok, reply} ->
          ORM.update(reply, %{reply_id: comment.id})

          {:ok, _} =
            PostCommentReply |> ORM.create(%{post_comment_id: comment.id, reply_id: reply.id})

          action.reactor |> ORM.find(reply.id)

        {:error, error} ->
          {:error, error}
      end
    end
  end

  # can not use spectial: post_comment_id
  def like_comment(part, comment_id, %Accounts.User{id: user_id}) do
    feel_comment(part, comment_id, user_id, :like)
  end

  def undo_like_comment(part, comment_id, %Accounts.User{id: user_id}) do
    undo_feel_comment(part, comment_id, user_id, :like)
  end

  def dislike_comment(part, comment_id, %Accounts.User{id: user_id}) do
    feel_comment(part, comment_id, user_id, :dislike)
  end

  def undo_dislike_comment(part, comment_id, %Accounts.User{id: user_id}) do
    undo_feel_comment(part, comment_id, user_id, :dislike)
  end

  defp feel_comment(part, comment_id, user_id, feeling)
       when valid_feeling(feeling) do
    with {:ok, action} <- match_action(part, feeling) do
      clause = %{post_comment_id: comment_id, user_id: user_id}

      case ORM.find_by(action.target, clause) do
        {:ok, _} ->
          {:error, "user has #{to_string(feeling)}d this comment"}

        {:error, _} ->
          action.target |> ORM.create(clause)
      end
    end
  end

  defp undo_feel_comment(part, comment_id, user_id, feeling) do
    with {:ok, action} <- match_action(part, feeling) do
      clause = %{post_comment_id: comment_id, user_id: user_id}
      ORM.findby_delete(action.target, clause)
    end
  end

  @doc """
  subscribe a community. (ONLY community, post etc use watch )
  """
  def subscribe_community(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, record} <- CommunitySubscriber |> ORM.create(~m(user_id community_id)a) do
      Community |> ORM.find(record.community_id)
    end
  end

  def unsubscribe_community(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, record} <-
           CommunitySubscriber |> ORM.findby_delete(community_id: community_id, user_id: user_id) do
      Community |> ORM.find(record.community_id)
    end
  end

  @doc """
  return paged community subscribers
  """
  def community_members(:editors, %Community{id: id}, filters) do
    load_community_members(id, CommunityEditor, filters)
  end

  def community_members(:subscribers, %Community{id: id}, filters) do
    load_community_members(id, CommunitySubscriber, filters)
  end

  defp load_community_members(id, modal, %{page: page, size: size} = filters) do
    modal
    |> where([c], c.community_id == ^id)
    |> QueryBuilder.load_inner_users(filters)
    |> ORM.paginater(page: page, size: size)
    |> done()
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

  # TODO passport should be public utils
  @doc """
  insert or update a user's passport in CMS context
  """
  def stamp_passport(%Accounts.User{id: user_id}, rules) do
    case ORM.find_by(Passport, user_id: user_id) do
      {:ok, passport} ->
        passport |> ORM.update(%{rules: deep_merge(passport.rules, rules)})

      {:error, _} ->
        Passport |> ORM.create(~m(user_id rules)a)
    end
  end

  def erase_passport(%Accounts.User{} = user, rules) when is_list(rules) do
    with {:ok, passport} <- ORM.find_by(Passport, user_id: user.id) do
      case pop_in(passport.rules, rules) do
        {nil, _} ->
          {:error, "#{rules} not found"}

        {_, lefts} ->
          passport |> ORM.update(%{rules: lefts})
      end
    end
  end

  @doc """
  return a user's passport in CMS context
  """
  def get_passport(%Accounts.User{} = user) do
    with {:ok, passport} <- ORM.find_by(Passport, user_id: user.id) do
      {:ok, passport.rules}
    end
  end

  # https://medium.com/front-end-hacking/use-github-oauth-as-your-sso-seamlessly-with-react-3e2e3b358fa1
  # http://www.ubazu.com/using-postgres-jsonb-columns-in-ecto
  # http://www.ubazu.com/using-postgres-jsonb-columns-in-ecto

  def list_passports(community, key) do
    Passport
    |> where([p], fragment("(?->?->>?)::boolean = ?", p.rules, ^community, ^key, true))
    |> Repo.all()
    |> done
  end
end
