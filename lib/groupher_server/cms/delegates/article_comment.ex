defmodule GroupherServer.CMS.Delegate.ArticleComment do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, get_config: 2]
  import Helper.ErrorCode

  import GroupherServer.CMS.Delegate.Helper, only: [mark_viewer_emotion_states: 3]
  import GroupherServer.CMS.Helper.Matcher2
  import ShortMaps

  alias Helper.Types, as: T
  alias Helper.{ORM, QueryBuilder}
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{ArticleComment, ArticlePinedComment, Embeds}
  alias Ecto.Multi

  @max_participator_count ArticleComment.max_participator_count()
  @default_emotions Embeds.ArticleCommentEmotion.default_emotions()
  @delete_hint ArticleComment.delete_hint()

  @default_comment_meta Embeds.ArticleCommentMeta.default_meta()
  @pined_comment_limit ArticleComment.pined_comment_limit()

  @doc """
  [timeline-mode] list paged article comments
  """

  def paged_article_comments(thread, article_id, filters, mode, user \\ nil)

  def paged_article_comments(thread, article_id, filters, :timeline, user) do
    where_query = dynamic([c], not c.is_folded and not c.is_pinned)
    do_paged_article_comment(thread, article_id, filters, where_query, user)
  end

  @doc """
  [replies-mode] list paged article comments
  """
  def paged_article_comments(thread, article_id, filters, :replies, user) do
    where_query =
      dynamic(
        [c],
        is_nil(c.reply_to_id) and not c.is_folded and not c.is_pinned
      )

    do_paged_article_comment(thread, article_id, filters, where_query, user)
  end

  def paged_folded_article_comments(thread, article_id, filters) do
    where_query = dynamic([c], c.is_folded and not c.is_pinned)
    do_paged_article_comment(thread, article_id, filters, where_query, nil)
  end

  def paged_folded_article_comments(thread, article_id, filters, user) do
    where_query = dynamic([c], c.is_folded and not c.is_pinned)
    do_paged_article_comment(thread, article_id, filters, where_query, user)
  end

  @doc """
  list paged comment replies
  """
  def paged_comment_replies(comment_id, filters, user \\ nil)

  def paged_comment_replies(comment_id, filters, user) do
    do_paged_comment_replies(comment_id, filters, user)
  end

  @spec paged_article_comments_participators(T.comment_thread(), Integer.t(), T.paged_filter()) ::
          {:ok, T.paged_users()}
  def paged_article_comments_participators(thread, article_id, filters) do
    %{page: page, size: size} = filters

    with {:ok, thread_query} <- match(thread, :query, article_id) do
      ArticleComment
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
  def create_article_comment(thread, article_id, content, %User{} = user) do
    with {:ok, info} <- match(thread),
         # make sure the article exsit
         # author is passed by middleware, it's exsit for sure
         {:ok, article} <- ORM.find(info.model, article_id, preload: [author: :user]) do
      Multi.new()
      |> Multi.run(:create_article_comment, fn _, _ ->
        do_create_comment(content, info.foreign_key, article, user)
      end)
      |> Multi.run(:update_article_comments_count, fn _, %{create_article_comment: comment} ->
        update_article_comments_count(comment, :inc)
      end)
      |> Multi.run(:add_participator, fn _, _ ->
        add_participator_to_article(article, user)
      end)
      |> Repo.transaction()
      |> upsert_comment_result()
    end
  end

  @doc """
  update a comment for article like psot, job ...
  """
  def update_article_comment(%ArticleComment{} = article_comment, content) do
    article_comment |> ORM.update(%{body_html: content})
  end

  @doc "delete article comment"
  def delete_article_comment(%ArticleComment{} = comment) do
    Multi.new()
    |> Multi.run(:update_article_comments_count, fn _, _ ->
      update_article_comments_count(comment, :dec)
    end)
    |> Multi.run(:remove_pined_comment, fn _, _ ->
      ORM.findby_delete(ArticlePinedComment, %{article_comment_id: comment.id})
    end)
    |> Multi.run(:delete_article_comment, fn _, _ ->
      ORM.update(comment, %{body_html: @delete_hint, is_deleted: true})
    end)
    |> Repo.transaction()
    |> upsert_comment_result()
  end

  # add participator to article-like content (Post, Job ...) and update count
  def add_participator_to_article(
        %{article_comments_participators: article_comments_participators} = article,
        %User{} = user
      ) do
    total_participators = article_comments_participators |> List.insert_at(0, user) |> Enum.uniq()
    new_comment_participators = total_participators |> Enum.slice(0, @max_participator_count)
    total_participators_count = length(total_participators)

    article
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_change(:article_comments_participators_count, total_participators_count)
    |> Ecto.Changeset.put_embed(:article_comments_participators, new_comment_participators)
    |> Repo.update()
  end

  def add_participator_to_article(_, _), do: {:ok, :pass}

  # update comment's parent article's comments total count
  @spec update_article_comments_count(ArticleComment.t(), :inc | :dec) :: ArticleComment.t()
  def update_article_comments_count(%ArticleComment{} = comment, opt) do
    with {:ok, article_info} <- match(:comment_article, comment),
         {:ok, article} <- ORM.find(article_info.model, article_info.id) do
      count_query =
        from(c in ArticleComment, where: field(c, ^article_info.foreign_key) == ^article_info.id)

      cur_count = Repo.aggregate(count_query, :count)

      # dec 是 comment 还没有删除的时候的操作，和 inc 不同
      # 因为 dec 操作如果放在 delete 后面，那么 update 会失败
      case opt do
        :inc -> ORM.update(article, %{article_comments_count: cur_count})
        :dec -> ORM.update(article, %{article_comments_count: Enum.max([1, cur_count]) - 1})
      end
    end
  end

  # creat article comment for parent or reply
  # set floor
  # TODO: parse editor-json
  # set default emotions
  def do_create_comment(content, foreign_key, article, %User{id: user_id}) do
    count_query = from(c in ArticleComment, where: field(c, ^foreign_key) == ^article.id)
    floor = Repo.aggregate(count_query, :count) + 1

    ArticleComment
    |> ORM.create(
      Map.put(
        %{
          author_id: user_id,
          body_html: content,
          emotions: @default_emotions,
          floor: floor,
          is_article_author: user_id == article.author.user.id,
          meta: @default_comment_meta
        },
        foreign_key,
        article.id
      )
    )
  end

  defp do_paged_article_comment(thread, article_id, filters, where_query, user) do
    %{page: page, size: size} = filters
    sort = Map.get(filters, :sort, :asc_inserted)

    with {:ok, thread_query} <- match(thread, :query, article_id) do
      query = from(c in ArticleComment, preload: [reply_to: :author])

      query
      |> where(^thread_query)
      |> where(^where_query)
      # |> QueryBuilder.filter_pack(Map.merge(filters, %{sort: :asc_inserted}))
      |> QueryBuilder.filter_pack(Map.merge(filters, %{sort: sort}))
      |> ORM.paginater(~m(page size)a)
      |> add_pined_comments_ifneed(thread, article_id, filters)
      |> mark_viewer_emotion_states(user, :comment)
      |> mark_viewer_has_upvoted(user)
      |> done()
    end
  end

  defp do_paged_comment_replies(comment_id, filters, user) do
    %{page: page, size: size} = filters
    query = from(c in ArticleComment, preload: [reply_to: :author])

    where_query = dynamic([c], not c.is_folded and c.reply_to_id == ^comment_id)

    query
    |> where(^where_query)
    |> QueryBuilder.filter_pack(filters)
    |> ORM.paginater(~m(page size)a)
    |> mark_viewer_emotion_states(user, :comment)
    |> mark_viewer_has_upvoted(user)
    |> done()
  end

  defp add_pined_comments_ifneed(%{entries: entries} = paged_comments, thread, article_id, %{
         page: 1
       }) do
    with {:ok, info} <- match(thread),
         query <-
           from(p in ArticlePinedComment,
             join: c in ArticleComment,
             on: p.article_comment_id == c.id,
             where: field(p, ^info.foreign_key) == ^article_id,
             select: c
           ),
         {:ok, pined_comments} <- Repo.all(query) |> done() do
      case pined_comments do
        [] ->
          paged_comments

        _ ->
          preloaded_pined_comments =
            Enum.slice(pined_comments, 0, @pined_comment_limit) |> Repo.preload(reply_to: :author)

          entries = Enum.concat(preloaded_pined_comments, entries)
          pined_comment_count = length(pined_comments)

          total_count = paged_comments.total_count + pined_comment_count
          paged_comments |> Map.merge(%{entries: entries, total_count: total_count})
      end
    end
  end

  defp add_pined_comments_ifneed(paged_comments, _thread, _article_id, _), do: paged_comments

  defp mark_viewer_has_upvoted(paged_comments, nil), do: paged_comments

  defp mark_viewer_has_upvoted(%{entries: entries} = paged_comments, %User{} = user) do
    entries =
      Enum.map(
        entries,
        &Map.merge(&1, %{viewer_has_upvoted: Enum.member?(&1.meta.upvoted_user_ids, user.id)})
      )

    Map.merge(paged_comments, %{entries: entries})
  end

  defp upsert_comment_result({:ok, %{create_article_comment: result}}), do: {:ok, result}
  defp upsert_comment_result({:ok, %{delete_article_comment: result}}), do: {:ok, result}

  defp upsert_comment_result({:error, :create_article_comment, result, _steps}) do
    raise_error(:create_comment, result)
  end

  defp upsert_comment_result({:error, :add_participator, result, _steps}) do
    {:error, result}
  end

  defp upsert_comment_result({:error, _, result, _steps}), do: {:error, result}
end
