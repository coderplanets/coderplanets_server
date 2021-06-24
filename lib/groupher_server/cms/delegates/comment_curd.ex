defmodule GroupherServer.CMS.Delegate.CommentCurd do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, ensure: 2]
  import Helper.ErrorCode

  import GroupherServer.CMS.Delegate.Helper, only: [mark_viewer_emotion_states: 3]
  import GroupherServer.CMS.Helper.Matcher
  import ShortMaps

  alias Helper.Types, as: T
  alias Helper.{Later, ORM, QueryBuilder, Converter}
  alias GroupherServer.{Accounts, CMS, Repo}
  alias CMS.Model.Post
  alias CMS.Delegate.Hooks

  alias Accounts.Model.User
  alias CMS.Model.{Comment, PinnedComment, Embeds}
  alias Ecto.Multi

  @max_participator_count Comment.max_participator_count()
  @default_emotions Embeds.CommentEmotion.default_emotions()
  @delete_hint Comment.delete_hint()

  @default_article_meta Embeds.ArticleMeta.default_meta()
  @default_comment_meta Embeds.CommentMeta.default_meta()
  @pinned_comment_limit Comment.pinned_comment_limit()

  @doc """
  [timeline-mode] list paged article comments
  """

  def paged_comments(thread, article_id, filters, mode, user \\ nil)

  def paged_comments(thread, article_id, filters, :timeline, user) do
    where_query = dynamic([c], not c.is_folded and not c.is_pinned)
    do_paged_comment(thread, article_id, filters, where_query, user)
  end

  @doc """
  [replies-mode] list paged article comments
  """
  def paged_comments(thread, article_id, filters, :replies, user) do
    where_query =
      dynamic(
        [c],
        is_nil(c.reply_to_id) and not c.is_folded and not c.is_pinned
      )

    do_paged_comment(thread, article_id, filters, where_query, user)
  end

  def paged_published_comments(%User{id: user_id}, filter) do
    %{page: page, size: size} = filter

    Comment
    |> join(:inner, [comment], author in assoc(comment, :author))
    |> where([comment, author], author.id == ^user_id)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(~m(page size)a)
    |> ORM.extract_and_assign_article()
    |> done()
  end

  def paged_published_comments(%User{id: user_id}, thread, filter) do
    %{page: page, size: size} = filter

    thread = thread |> to_string |> String.upcase()
    thread_atom = thread |> String.downcase() |> String.to_atom()

    article_preload = Keyword.new([{thread_atom, [author: :user]}])
    query = from(comment in Comment, preload: ^article_preload)

    query
    |> join(:inner, [comment], author in assoc(comment, :author))
    |> where([comment, author], comment.thread == ^thread)
    |> where([comment, author], author.id == ^user_id)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(~m(page size)a)
    |> ORM.extract_and_assign_article()
    |> done()
  end

  def paged_folded_comments(thread, article_id, filters) do
    where_query = dynamic([c], c.is_folded and not c.is_pinned)
    do_paged_comment(thread, article_id, filters, where_query, nil)
  end

  def paged_folded_comments(thread, article_id, filters, user) do
    where_query = dynamic([c], c.is_folded and not c.is_pinned)
    do_paged_comment(thread, article_id, filters, where_query, user)
  end

  @doc """
  list paged comment replies
  """
  def paged_comment_replies(comment_id, filters, user \\ nil)

  def paged_comment_replies(comment_id, filters, user) do
    do_paged_comment_replies(comment_id, filters, user)
  end

  @spec paged_comments_participants(T.article_thread(), Integer.t(), T.paged_filter()) ::
          {:ok, T.paged_users()}
  def paged_comments_participants(thread, article_id, filters) do
    %{page: page, size: size} = filters

    with {:ok, thread_query} <- match(thread, :query, article_id) do
      Comment
      |> where(^thread_query)
      |> QueryBuilder.filter_pack(Map.merge(filters, %{sort: :desc_inserted}))
      |> join(:inner, [c], a in assoc(c, :author))
      |> distinct([c, a], a.id)
      |> group_by([c, a], a.id)
      |> group_by([c, a], c.inserted_at)
      |> select([c, a], a)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  @doc """
  creates a comment for article like psot, job ...
  """
  def create_comment(thread, article_id, body, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: [author: :user]),
         true <- can_comment?(article, user) do
      Multi.new()
      |> Multi.run(:create_comment, fn _, _ ->
        do_create_comment(body, info.foreign_key, article, user)
      end)
      |> Multi.run(:update_comments_count, fn _, %{create_comment: comment} ->
        update_comments_count(comment, :inc)
      end)
      |> Multi.run(:set_question_flag_ifneed, fn _, %{create_comment: comment} ->
        set_question_flag_ifneed(article, comment)
      end)
      |> Multi.run(:add_participator, fn _, _ -> add_participant_to_article(article, user) end)
      |> Multi.run(:update_article_active_timestamp, fn _, %{create_comment: comment} ->
        case comment.author_id == article.author.user.id do
          true -> {:ok, :pass}
          false -> CMS.update_active_timestamp(thread, article)
        end
      end)
      |> Multi.run(:after_hooks, fn _, %{create_comment: comment} ->
        Later.run({Hooks.Cite, :handle, [comment]})
        Later.run({Hooks.Notify, :handle, [:comment, comment, user]})
        Later.run({Hooks.Mention, :handle, [comment]})
      end)
      |> Repo.transaction()
      |> result()
    else
      false -> raise_error(:article_comments_locked, "this article is forbid comment")
      {:error, error} -> {:error, error}
    end
  end

  @doc "check is article can be comemnt or not"
  # TODO: check if use is in author's block list?
  def can_comment?(article, _user) do
    article_meta = ensure(article.meta, @default_article_meta)

    not article_meta.is_comment_locked
  end

  @doc """
  update a comment for article like psot, job ...
  """
  # 如果是 solution, 那么要更新对应的 post 的 solution_digest
  def update_comment(%Comment{is_solution: true} = comment, body) do
    with {:ok, post} <- ORM.find(Post, comment.post_id),
         {:ok, parsed} <- Converter.Article.parse_body(body),
         {:ok, digest} <- Converter.Article.parse_digest(parsed.body_map) do
      %{body: body, body_html: body_html} = parsed
      post |> ORM.update(%{solution_digest: digest})
      comment |> ORM.update(%{body: body, body_html: body_html})
    end
  end

  def update_comment(%Comment{} = comment, body) do
    with {:ok, %{body: body, body_html: body_html}} <- Converter.Article.parse_body(body) do
      comment |> ORM.update(%{body: body, body_html: body_html})
    end
  end

  @doc """
  mark a comment as question post's best solution
  """
  def mark_comment_solution(comment_id, user) do
    with {:ok, comment} <- ORM.find(Comment, comment_id),
         {:ok, post} <- ORM.find(Post, comment.post_id, preload: [author: :user]) do
      # 确保只有一个最佳答案
      batch_update_solution_flag(post, false)
      CMS.pin_comment(comment.id)
      do_mark_comment_solution(post, comment, user, true)
    end
  end

  @doc """
  undo mark a comment as question post's best solution
  """
  def undo_mark_comment_solution(comment_id, user) do
    with {:ok, comment} <- ORM.find(Comment, comment_id),
         {:ok, post} <- ORM.find(Post, comment.post_id, preload: [author: :user]) do
      do_mark_comment_solution(post, comment, user, false)
    end
  end

  defp do_mark_comment_solution(post, %Comment{} = comment, user, is_solution) do
    # check if user is questioner
    with true <- user.id == post.author.user.id do
      Multi.new()
      |> Multi.run(:mark_solution, fn _, _ ->
        ORM.update(comment, %{is_solution: is_solution, is_for_question: true})
      end)
      |> Multi.run(:update_post_state, fn _, _ ->
        ORM.update(post, %{is_solved: is_solution, solution_digest: comment.body_html})
      end)
      |> Repo.transaction()
      |> result()
    else
      false -> raise_error(:require_questioner, "oops, questioner only")
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  batch update is_question flag for post-only article
  """
  def batch_update_question_flag(%Post{is_question: is_question} = post) do
    from(c in Comment,
      where: c.post_id == ^post.id,
      update: [set: [is_for_question: ^is_question]]
    )
    |> Repo.update_all([])

    {:ok, :pass}
  end

  def batch_update_question_flag(_), do: {:ok, :pass}

  @doc "delete article comment"
  def delete_comment(%Comment{} = comment) do
    Multi.new()
    |> Multi.run(:update_comments_count, fn _, _ ->
      update_comments_count(comment, :dec)
    end)
    |> Multi.run(:remove_pined_comment, fn _, _ ->
      ORM.findby_delete(PinnedComment, %{comment_id: comment.id})
    end)
    |> Multi.run(:delete_comment, fn _, _ ->
      ORM.update(comment, %{body_html: @delete_hint, is_deleted: true})
    end)
    |> Repo.transaction()
    |> result()
  end

  # add participator to article-like(Post, Job ...) and update count
  def add_participant_to_article(
        %{comments_participants: participants} = article,
        %User{} = user
      ) do
    total_participants = participants |> List.insert_at(0, user) |> Enum.uniq_by(& &1.id)

    latest_participants = total_participants |> Enum.slice(0, @max_participator_count)
    total_participants_count = length(total_participants)

    article
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_change(:comments_participants_count, total_participants_count)
    |> Ecto.Changeset.put_embed(:comments_participants, latest_participants)
    |> Repo.update()
  end

  def add_participant_to_article(_, _), do: {:ok, :pass}

  # update comment's parent article's comments total count
  @spec update_comments_count(Comment.t(), :inc | :dec) :: Comment.t()
  def update_comments_count(%Comment{} = comment, opt) do
    with {:ok, article_info} <- match(:comment_article, comment),
         {:ok, article} <- ORM.find(article_info.model, article_info.id) do
      {:ok, cur_count} =
        from(c in Comment, where: field(c, ^article_info.foreign_key) == ^article_info.id)
        |> ORM.count()

      # dec 是 comment 还没有删除的时候的操作，和 inc 不同
      # 因为 dec 操作如果放在 delete 后面，那么 update 会失败
      case opt do
        :inc -> ORM.update(article, %{comments_count: cur_count})
        :dec -> ORM.update(article, %{comments_count: Enum.max([1, cur_count]) - 1})
      end
    end
  end

  @doc """
  create article comment for parent or reply
  """
  def do_create_comment(body, foreign_key, article, %User{id: user_id}) do
    with {:ok, %{body: body, body_html: body_html}} <- Converter.Article.parse_body(body) do
      # e.g: :post_id -> "POST", :job_id -> "JOB"
      thread = foreign_key |> to_string |> String.slice(0..-4) |> String.upcase()

      attrs = %{
        author_id: user_id,
        body: body,
        body_html: body_html,
        emotions: @default_emotions,
        floor: next_floor(article, foreign_key),
        is_article_author: user_id == article.author.user.id,
        thread: thread,
        meta: @default_comment_meta
      }

      Comment |> ORM.create(Map.put(attrs, foreign_key, article.id))
    end
  end

  defp do_paged_comment(thread, article_id, filters, where_query, user) do
    %{page: page, size: size} = filters
    sort = Map.get(filters, :sort, :asc_inserted)

    with {:ok, thread_query} <- match(thread, :query, article_id) do
      query = from(c in Comment, preload: [reply_to: :author])

      query
      |> where(^thread_query)
      |> where(^where_query)
      |> QueryBuilder.filter_pack(Map.merge(filters, %{sort: sort}))
      |> ORM.paginater(~m(page size)a)
      |> add_pinned_comments_ifneed(thread, article_id, filters)
      |> mark_viewer_emotion_states(user, :comment)
      |> mark_viewer_has_upvoted(user)
      |> done()
    end
  end

  defp do_paged_comment_replies(comment_id, filters, user) do
    %{page: page, size: size} = filters
    query = from(c in Comment, preload: [reply_to: :author])

    where_query = dynamic([c], not c.is_folded and c.reply_to_id == ^comment_id)

    query
    |> where(^where_query)
    |> QueryBuilder.filter_pack(filters)
    |> ORM.paginater(~m(page size)a)
    |> mark_viewer_emotion_states(user, :comment)
    |> mark_viewer_has_upvoted(user)
    |> done()
  end

  defp add_pinned_comments_ifneed(paged_comments, thread, article_id, %{page: 1}) do
    with {:ok, info} <- match(thread),
         {:ok, pinned_comments} <- list_pinned_comments(info, article_id) do
      case pinned_comments do
        [] ->
          paged_comments

        _ ->
          pinned_comments =
            sort_solution_to_front(thread, pinned_comments)
            |> Enum.slice(0, @pinned_comment_limit)
            |> Repo.preload(reply_to: :author)

          entries = pinned_comments ++ paged_comments.entries
          pinned_comment_count = length(pinned_comments)

          total_count = paged_comments.total_count + pinned_comment_count
          paged_comments |> Map.merge(%{entries: entries, total_count: total_count})
      end
    end
  end

  defp add_pinned_comments_ifneed(paged_comments, _thread, _article_id, _), do: paged_comments

  defp list_pinned_comments(%{foreign_key: foreign_key}, article_id) do
    from(p in PinnedComment,
      join: c in Comment,
      on: p.comment_id == c.id,
      where: field(p, ^foreign_key) == ^article_id,
      order_by: [desc: p.inserted_at],
      select: c
    )
    |> Repo.all()
    |> done
  end

  # only support post
  defp sort_solution_to_front(:post, pinned_comments) do
    solution_index = Enum.find_index(pinned_comments, & &1.is_solution)

    case is_nil(solution_index) do
      true ->
        pinned_comments

      false ->
        {solution_comment, rest_comments} = List.pop_at(pinned_comments, solution_index)
        [solution_comment] ++ rest_comments
    end
  end

  defp sort_solution_to_front(_, pinned_comments), do: pinned_comments

  defp mark_viewer_has_upvoted(paged_comments, nil), do: paged_comments

  defp mark_viewer_has_upvoted(%{entries: entries} = paged_comments, %User{} = user) do
    entries =
      Enum.map(
        entries,
        &Map.merge(&1, %{viewer_has_upvoted: Enum.member?(&1.meta.upvoted_user_ids, user.id)})
      )

    Map.merge(paged_comments, %{entries: entries})
  end

  defp set_question_flag_ifneed(%{is_question: true} = _article, %Comment{} = comment) do
    ORM.update(comment, %{is_for_question: true})
  end

  defp set_question_flag_ifneed(_, comment), do: ORM.update(comment, %{is_for_question: false})

  # batch update is_solution flag for artilce comment
  defp batch_update_solution_flag(%Post{} = post, is_question) do
    from(c in Comment,
      where: c.post_id == ^post.id,
      update: [set: [is_solution: ^is_question]]
    )
    |> Repo.update_all([])

    {:ok, :pass}
  end

  # get next floor under an article's comments list
  defp next_floor(article, foreign_key) do
    {:ok, cur_count} =
      from(c in Comment, where: field(c, ^foreign_key) == ^article.id)
      |> ORM.count()

    cur_count + 1
  end

  defp result({:ok, %{set_question_flag_ifneed: result}}), do: {:ok, result}
  defp result({:ok, %{delete_comment: result}}), do: {:ok, result}
  defp result({:ok, %{mark_solution: result}}), do: {:ok, result}

  defp result({:error, :create_comment, result, _steps}) do
    raise_error(:create_comment, result)
  end

  defp result({:error, _, result, _steps}), do: {:error, result}
end
