defmodule GroupherServer.CMS.Delegate.ArticleCommentAction do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, strip_struct: 1]
  import Helper.ErrorCode

  import GroupherServer.CMS.Utils.Matcher2

  alias Helper.Types, as: T
  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User

  alias CMS.{
    ArticleComment,
    ArticlePinedComment,
    ArticleCommentUpvote,
    ArticleCommentReply,
    Embeds,
    Post,
    Job
  }

  alias Ecto.Multi

  @max_participator_count ArticleComment.max_participator_count()
  @max_parent_replies_count ArticleComment.max_parent_replies_count()
  @default_emotions Embeds.ArticleCommentEmotion.default_emotions()
  @report_threshold_for_fold ArticleComment.report_threshold_for_fold()

  @default_comment_meta Embeds.ArticleCommentMeta.default_meta()
  @pined_comment_limit ArticleComment.pined_comment_limit()

  @spec pin_article_comment(Integer.t()) :: {:ok, ArticleComment.t()}
  @doc "pin a comment"
  def pin_article_comment(comment_id) do
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id),
         {:ok, full_comment} <- get_full_comment(comment.id),
         {:ok, info} <- match(full_comment.thread) do
      Multi.new()
      |> Multi.run(:checked_pined_comments_count, fn _, _ ->
        count_query =
          from(p in ArticlePinedComment,
            where: field(p, ^info.foreign_key) == ^full_comment.article.id
          )

        pined_comments_count = Repo.aggregate(count_query, :count)

        case pined_comments_count >= @pined_comment_limit do
          true -> {:error, "only support #{@pined_comment_limit} pined comment for each article"}
          false -> {:ok, :pass}
        end
      end)
      |> Multi.run(:update_comment_flag, fn _, _ ->
        ORM.update(comment, %{is_pinned: true})
      end)
      |> Multi.run(:add_pined_comment, fn _, _ ->
        ArticlePinedComment
        |> ORM.create(
          %{article_comment_id: comment.id}
          |> Map.put(info.foreign_key, full_comment.article.id)
        )
      end)
      |> Repo.transaction()
      |> upsert_comment_result()
    end
  end

  def undo_pin_article_comment(comment_id) do
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id) do
      Multi.new()
      |> Multi.run(:update_comment_flag, fn _, _ ->
        ORM.update(comment, %{is_pinned: false})
      end)
      |> Multi.run(:remove_pined_comment, fn _, _ ->
        ORM.findby_delete(ArticlePinedComment, %{article_comment_id: comment.id})
      end)
      |> Repo.transaction()
      |> upsert_comment_result()
    end
  end

  def fold_article_comment(%ArticleComment{} = comment, %User{} = _user) do
    comment |> ORM.update(%{is_folded: true})
  end

  @doc "fold a comment"
  def fold_article_comment(comment_id, %User{} = _user) do
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id) do
      comment |> ORM.update(%{is_folded: true})
    end
  end

  @doc "fold a comment"
  def unfold_article_comment(comment_id, %User{} = _user) do
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id) do
      comment |> ORM.update(%{is_folded: false})
    end
  end

  @doc "fold a comment"
  def report_article_comment(comment_id, %User{} = user) do
    with {:ok, comment} <-
           ORM.find(ArticleComment, comment_id) do
      Multi.new()
      |> Multi.run(:create_abuse_report, fn _, _ ->
        CMS.create_report(:article_comment, comment_id, %{reason: "todo fucked"}, user)
      end)
      |> Multi.run(:update_report_flag, fn _, _ ->
        ORM.update(comment, %{is_reported: true})
      end)
      |> Multi.run(:fold_comment_report_too_many, fn _, %{create_abuse_report: abuse_report} ->
        if abuse_report.report_cases_count >= @report_threshold_for_fold,
          do: fold_article_comment(comment, user),
          else: {:ok, comment}
      end)
      |> Repo.transaction()
      |> upsert_comment_result()
    end
  end

  @doc "fold a comment"
  def unreport_article_comment(comment_id, %User{} = _user) do
    with {:ok, comment} <-
           ORM.find(ArticleComment, comment_id) do
      comment |> ORM.update(%{is_reported: false})
    end
  end

  @doc "reply to exsiting comment"
  def reply_article_comment(comment_id, content, %User{} = user) do
    with {:ok, target_comment} <-
           ORM.find_by(ArticleComment, %{id: comment_id, is_deleted: false}),
         replying_comment <- Repo.preload(target_comment, reply_to: :author),
         {thread, article} <- get_article(replying_comment),
         {:ok, info} <- match(thread),
         parent_comment <- get_parent_comment(replying_comment) do
      Multi.new()
      |> Multi.run(:create_reply_comment, fn _, _ ->
        do_create_comment(content, info.foreign_key, article, user)
      end)
      |> Multi.run(:update_article_comments_count, fn _,
                                                      %{create_reply_comment: replyed_comment} ->
        update_article_comments_count(replyed_comment, :inc)
      end)
      |> Multi.run(:create_article_comment_reply, fn _,
                                                     %{create_reply_comment: replyed_comment} ->
        ArticleCommentReply
        |> ORM.create(%{article_comment_id: replyed_comment.id, reply_to_id: replying_comment.id})
      end)
      |> Multi.run(:inc_replies_count, fn _, _ ->
        ORM.inc_field(ArticleComment, replying_comment, :replies_count)
      end)
      |> Multi.run(:add_replies_ifneed, fn _, %{create_reply_comment: replyed_comment} ->
        add_replies_ifneed(parent_comment, replyed_comment)
      end)
      |> Multi.run(:add_participator, fn _, _ ->
        add_participator_to_article(article, user)
      end)
      |> Multi.run(:set_meta_flag, fn _, %{create_reply_comment: replyed_comment} ->
        update_reply_to_others_state(parent_comment, replying_comment, replyed_comment)
      end)
      |> Multi.run(:add_reply_to, fn _, %{create_reply_comment: replyed_comment} ->
        replyed_comment
        |> Repo.preload(:reply_to)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:reply_to, replying_comment)
        |> Repo.update()
      end)
      |> Repo.transaction()
      |> upsert_comment_result()
    end
  end

  @doc "upvote a comment"
  def upvote_article_comment(comment_id, %User{id: user_id}) do
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id),
         false <- comment.is_deleted do
      # TODO: is user upvoted before?
      Multi.new()
      |> Multi.run(:create_comment_upvote, fn _, _ ->
        ORM.create(ArticleCommentUpvote, %{article_comment_id: comment.id, user_id: user_id})
      end)
      |> Multi.run(:add_upvoted_user, fn _, _ ->
        update_upvoted_user_list(comment, user_id, :add)
      end)
      |> Multi.run(:inc_upvotes_count, fn _, %{add_upvoted_user: comment} ->
        count_query = from(c in ArticleCommentUpvote, where: c.article_comment_id == ^comment.id)
        upvotes_count = Repo.aggregate(count_query, :count)
        ORM.update(comment, %{upvotes_count: upvotes_count})
      end)
      |> Multi.run(:check_article_author_upvoted, fn _, %{inc_upvotes_count: comment} ->
        update_article_author_upvoted_info(comment, user_id)
      end)
      |> Repo.transaction()
      |> upsert_comment_result()
    end
  end

  @doc "upvote a comment"
  def undo_upvote_article_comment(comment_id, %User{id: user_id}) do
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id),
         false <- comment.is_deleted do
      Multi.new()
      |> Multi.run(:delete_comment_upvote, fn _, _ ->
        ORM.findby_delete(ArticleCommentUpvote, %{
          article_comment_id: comment.id,
          user_id: user_id
        })
      end)
      |> Multi.run(:remove_upvoted_user, fn _, _ ->
        update_upvoted_user_list(comment, user_id, :remove)
      end)
      |> Multi.run(:desc_upvotes_count, fn _, %{remove_upvoted_user: comment} ->
        count_query = from(c in ArticleCommentUpvote, where: c.article_comment_id == ^comment_id)
        upvotes_count = Repo.aggregate(count_query, :count)

        ORM.update(comment, %{upvotes_count: Enum.max([upvotes_count - 1, 0])})
      end)
      |> Multi.run(:check_article_author_upvoted, fn _, %{desc_upvotes_count: updated_comment} ->
        update_article_author_upvoted_info(updated_comment, user_id)
      end)
      |> Repo.transaction()
      |> upsert_comment_result()
    end
  end

  defp update_article_author_upvoted_info(%ArticleComment{} = comment, user_id) do
    with {:ok, article} = get_full_comment(comment.id) do
      is_article_author_upvoted = article.author.id == user_id

      new_meta =
        comment.meta
        |> Map.from_struct()
        |> Map.merge(%{is_article_author_upvoted: is_article_author_upvoted})

      comment |> ORM.update(%{meta: new_meta})
    end
  end

  # update comment's parent article's comments total count
  @spec update_article_comments_count(ArticleComment.t(), :inc | :dec) :: ArticleComment.t()
  defp update_article_comments_count(%ArticleComment{} = comment, opt) do
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
  defp do_create_comment(content, foreign_key, article, %User{id: user_id}) do
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

  # 设计盖楼只保留一个层级，回复楼中的评论都会被放到顶楼的 replies 中
  defp get_parent_comment(%ArticleComment{reply_to_id: nil} = comment) do
    comment
  end

  defp get_parent_comment(%ArticleComment{reply_to_id: reply_to_id} = comment)
       when not is_nil(reply_to_id) do
    get_parent_comment(Repo.preload(comment.reply_to, reply_to: :author))
  end

  # 如果 replies 没有达到 @max_parent_replies_count, 则添加
  # "加载更多" 的逻辑使用另外的 paged 接口从 ArticleCommentReply 表中查询
  defp add_replies_ifneed(
         %ArticleComment{replies: replies} = parent_comment,
         %ArticleComment{} = replyed_comment
       )
       when length(replies) < @max_parent_replies_count do
    new_replies =
      replies
      |> List.insert_at(length(replies), replyed_comment)
      |> Enum.slice(0, @max_parent_replies_count)

    parent_comment
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:replies, new_replies)
    |> Repo.update()
  end

  # 如果已经有 @max_parent_replies_count 以上的回复了，直接忽略即可
  defp add_replies_ifneed(%ArticleComment{} = parent_comment, _) do
    {:ok, parent_comment}
  end

  # add participator to article-like content (Post, Job ...) and update count
  defp add_participator_to_article(%Post{} = article, %User{} = user) do
    total_participators =
      article.article_comments_participators
      |> List.insert_at(0, user)
      |> Enum.uniq()

    new_comment_participators = total_participators |> Enum.slice(0, @max_participator_count)

    total_participators_count = length(total_participators)

    article
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_change(:article_comments_participators_count, total_participators_count)
    |> Ecto.Changeset.put_embed(:article_comments_participators, new_comment_participators)
    |> Repo.update()
  end

  defp add_participator_to_article(_, _), do: {:ok, :pass}

  defp get_article(%ArticleComment{post_id: post_id} = comment) when not is_nil(post_id) do
    with {:ok, article} <- ORM.find(Post, comment.post_id, preload: [author: :user]) do
      {:post, article}
    end
  end

  defp get_article(%ArticleComment{job_id: job_id} = comment) when not is_nil(job_id) do
    with {:ok, article} <- ORM.find(Job, comment.job_id, preload: [author: :user]) do
      {:job, article}
    end
  end

  @spec get_full_comment(String.t()) :: {:ok, T.article_info()} | {:error, nil}
  defp get_full_comment(comment_id) do
    query = from(c in ArticleComment, where: c.id == ^comment_id, preload: :post, preload: :job)

    with {:ok, comment} <- Repo.one(query) |> done() do
      extract_article_info(comment)
    end
  end

  defp extract_article_info(%ArticleComment{post: %Post{} = post}) when not is_nil(post) do
    do_extract_article_info(:post, post)
  end

  defp extract_article_info(%ArticleComment{job: %Job{} = job}) when not is_nil(job) do
    do_extract_article_info(:job, job)
  end

  @spec do_extract_article_info(T.article_thread(), T.article_common()) :: {:ok, T.article_info()}
  defp do_extract_article_info(thread, article) do
    with {:ok, article_with_author} <- Repo.preload(article, author: :user) |> done(),
         article_author <- get_in(article_with_author, [:author, :user]) do
      #
      article_info = %{title: article.title, id: article.id}

      author_info = %{
        id: article_author.id,
        login: article_author.login,
        nickname: article_author.nickname
      }

      {:ok, %{thread: thread, article: article_info, author: author_info}}
    end
  end

  # used in replies mode, for those reply to other user in replies box (for frontend)
  # 用于回复模式，指代这条回复是回复“回复列表其他人的” （方便前端展示）
  defp update_reply_to_others_state(parent_comment, replying_comment, replyed_comment) do
    replying_comment = replying_comment |> Repo.preload(:author)
    parent_comment = parent_comment |> Repo.preload(:author)
    is_reply_to_others = parent_comment.author.id !== replying_comment.author.id

    case is_reply_to_others do
      true ->
        new_meta =
          replyed_comment.meta
          |> Map.from_struct()
          |> Map.merge(%{is_reply_to_others: is_reply_to_others})

        ORM.update(replyed_comment, %{meta: new_meta})

      false ->
        {:ok, :pass}
    end
  end

  defp update_upvoted_user_list(comment, user_id, opt) do
    cur_user_ids = get_in(comment, [:meta, :upvoted_user_ids])

    user_ids =
      case opt do
        :add -> [user_id] ++ cur_user_ids
        :remove -> cur_user_ids -- [user_id]
      end

    meta = comment.meta |> Map.merge(%{upvoted_user_ids: user_ids}) |> strip_struct
    ORM.update_meta(comment, meta)
  end

  defp upsert_comment_result({:ok, %{create_article_comment: result}}), do: {:ok, result}
  defp upsert_comment_result({:ok, %{add_reply_to: result}}), do: {:ok, result}
  defp upsert_comment_result({:ok, %{check_article_author_upvoted: result}}), do: {:ok, result}
  defp upsert_comment_result({:ok, %{update_report_flag: result}}), do: {:ok, result}
  defp upsert_comment_result({:ok, %{update_comment_flag: result}}), do: {:ok, result}
  defp upsert_comment_result({:ok, %{delete_article_comment: result}}), do: {:ok, result}

  defp upsert_comment_result({:error, :create_article_comment, result, _steps}) do
    raise_error(:create_comment, result)
  end

  defp upsert_comment_result({:error, :add_participator, result, _steps}) do
    {:error, result}
  end

  defp upsert_comment_result({:error, :create_abuse_report, result, _steps}) do
    {:error, result}
  end

  defp upsert_comment_result({:error, _, result, _steps}), do: {:error, result}
end
