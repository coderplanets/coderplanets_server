defmodule GroupherServer.CMS.Delegate.CommentAction do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, strip_struct: 1, get_config: 2, ensure: 2]

  import GroupherServer.CMS.Delegate.Helper,
    only: [article_of: 1, thread_of: 1, sync_embed_replies: 1]

  import Helper.ErrorCode

  import GroupherServer.CMS.Delegate.CommentCURD,
    only: [
      add_participant_to_article: 2,
      do_create_comment: 4,
      update_comments_count: 2,
      can_comment?: 2,
      paged_comment_replies: 2
    ]

  import GroupherServer.CMS.Helper.Matcher

  alias Helper.Types, as: T
  alias Helper.{ORM, Later}
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.Model.User
  alias CMS.Model.{Comment, PinnedComment, CommentUpvote, CommentReply, Embeds}
  alias CMS.Delegate.Hooks

  alias Ecto.Multi

  @article_threads get_config(:article, :threads)

  @default_article_meta Embeds.ArticleMeta.default_meta()
  @max_parent_replies_count Comment.max_parent_replies_count()
  @pinned_comment_limit Comment.pinned_comment_limit()

  @doc "pin a comment"
  @spec pin_comment(Integer.t()) :: {:ok, Comment.t()}
  def pin_comment(comment_id) do
    with {:ok, comment} <- ORM.find(Comment, comment_id),
         {:ok, full_comment} <- get_full_comment(comment.id),
         {:ok, info} <- match(full_comment.thread) do
      Multi.new()
      |> Multi.run(:checked_pined_comments_count, fn _, _ ->
        pined_comments_query =
          from(p in PinnedComment,
            where: field(p, ^info.foreign_key) == ^full_comment.article.id
          )

        with {:ok, pined_comments_count} <- ORM.count(pined_comments_query) do
          case pined_comments_count >= @pinned_comment_limit do
            true -> {:error, "max #{@pinned_comment_limit} pinned comment for each article"}
            false -> {:ok, :pass}
          end
        end
      end)
      |> Multi.run(:update_comment_flag, fn _, _ ->
        ORM.update(comment, %{is_pinned: true})
      end)
      |> Multi.run(:add_pined_comment, fn _, _ ->
        attrs = %{comment_id: comment.id} |> Map.put(info.foreign_key, full_comment.article.id)

        PinnedComment |> ORM.create(attrs)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def undo_pin_comment(comment_id) do
    with {:ok, comment} <- ORM.find(Comment, comment_id) do
      Multi.new()
      |> Multi.run(:update_comment_flag, fn _, _ ->
        ORM.update(comment, %{is_pinned: false})
      end)
      |> Multi.run(:remove_pined_comment, fn _, _ ->
        ORM.findby_delete(PinnedComment, %{comment_id: comment.id})
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc "fold a comment"
  def fold_comment(%Comment{} = comment, %User{} = _user), do: do_fold_comment(comment, true)

  @doc "fold a comment by id"
  def fold_comment(comment_id, %User{} = _user) do
    with {:ok, comment} <- ORM.find(Comment, comment_id) do
      do_fold_comment(comment, true)
    end
  end

  @doc "unfold a comment"
  def unfold_comment(comment_id, %User{} = _user) do
    with {:ok, comment} <- ORM.find(Comment, comment_id) do
      do_fold_comment(comment, false)
    end
  end

  @doc "reply to exsiting comment"
  def reply_comment(comment_id, body, %User{} = user) do
    with {:ok, target_comment} <-
           ORM.find_by(Comment, %{id: comment_id, is_deleted: false}),
         replying_comment <- Repo.preload(target_comment, reply_to: :author),
         {thread, article} <- get_article(replying_comment),
         true <- can_comment?(article, user),
         {:ok, info} <- match(thread),
         parent_comment <- get_parent_comment(replying_comment) do
      Multi.new()
      |> Multi.run(:create_reply_comment, fn _, _ ->
        do_create_comment(body, info.foreign_key, article, user)
      end)
      |> Multi.run(:update_comments_count, fn _, %{create_reply_comment: replyed_comment} ->
        update_comments_count(replyed_comment, :inc)
      end)
      |> Multi.run(:create_comment_reply, fn _, %{create_reply_comment: replyed_comment} ->
        CommentReply
        |> ORM.create(%{comment_id: replyed_comment.id, reply_to_id: replying_comment.id})
      end)
      |> Multi.run(:add_participator, fn _, _ ->
        add_participant_to_article(article, user)
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
      |> Multi.run(:add_replies_ifneed, fn _, %{add_reply_to: replyed_comment} ->
        add_replies_ifneed(parent_comment, replyed_comment)
      end)
      |> Multi.run(:inc_replies_count, fn _, %{add_reply_to: replyed_comment} ->
        filter = %{page: 1, size: 1}

        with {:ok, paged_replies} <- paged_comment_replies(parent_comment.id, filter),
             {:ok, _} <- ORM.update(parent_comment, %{replies_count: paged_replies.total_count}) do
          {:ok, replyed_comment}
        end
      end)
      |> Multi.run(:after_hooks, fn _, %{add_reply_to: replyed_comment} ->
        Later.run({Hooks.Notify, :handle, [:reply, replyed_comment, user]})
        Later.run({Hooks.Mention, :handle, [replyed_comment]})
      end)
      |> Repo.transaction()
      |> result()
    else
      false -> raise_error(:article_comments_locked, "this article is forbid comment")
      {:error, error} -> {:error, error}
    end
  end

  @doc "upvote a comment"
  def upvote_comment(comment_id, %User{id: user_id} = from_user) do
    with {:ok, comment} <- ORM.find(Comment, comment_id),
         false <- comment.is_deleted do
      Multi.new()
      |> Multi.run(:create_comment_upvote, fn _, _ ->
        ORM.create(CommentUpvote, %{comment_id: comment.id, user_id: user_id})
      end)
      |> Multi.run(:add_upvoted_user, fn _, _ ->
        update_upvoted_user_list(comment, user_id, :add)
      end)
      |> Multi.run(:inc_upvotes_count, fn _, %{add_upvoted_user: comment} ->
        {:ok, upvotes_count} =
          from(c in CommentUpvote, where: c.comment_id == ^comment.id) |> ORM.count()

        ORM.update(comment, %{upvotes_count: upvotes_count})
      end)
      |> Multi.run(:check_article_author_upvoted, fn _, %{inc_upvotes_count: comment} ->
        update_article_author_upvoted_info(comment, user_id)
      end)
      |> Multi.run(:viewer_states, fn _, %{check_article_author_upvoted: comment} ->
        viewer_has_upvoted = Enum.member?(comment.meta.upvoted_user_ids, user_id)
        viewer_has_reported = Enum.member?(comment.meta.reported_user_ids, user_id)

        comment
        |> Map.merge(%{viewer_has_upvoted: viewer_has_upvoted})
        |> Map.merge(%{viewer_has_reported: viewer_has_reported})
        |> done
      end)
      |> Multi.run(:sync_embed_replies, fn _, %{viewer_states: comment} ->
        sync_embed_replies(comment)
      end)
      |> Multi.run(:after_hooks, fn _, _ ->
        Later.run({Hooks.Notify, :handle, [:upvote, comment, from_user]})
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc "upvote a comment"
  def undo_upvote_comment(comment_id, %User{id: user_id} = from_user) do
    with {:ok, comment} <- ORM.find(Comment, comment_id),
         false <- comment.is_deleted do
      Multi.new()
      |> Multi.run(:delete_comment_upvote, fn _, _ ->
        ORM.findby_delete(CommentUpvote, %{
          comment_id: comment.id,
          user_id: user_id
        })
      end)
      |> Multi.run(:remove_upvoted_user, fn _, _ ->
        update_upvoted_user_list(comment, user_id, :remove)
      end)
      |> Multi.run(:desc_upvotes_count, fn _, %{remove_upvoted_user: comment} ->
        {:ok, upvotes_count} =
          from(c in CommentUpvote, where: c.comment_id == ^comment_id) |> ORM.count()

        ORM.update(comment, %{upvotes_count: Enum.max([upvotes_count, 0])})
      end)
      |> Multi.run(:unset_article_author_upvoted, fn _, %{desc_upvotes_count: updated_comment} ->
        meta = updated_comment.meta |> Map.put(:is_article_author_upvoted, false)
        updated_comment |> ORM.update_meta(meta)
      end)
      |> Multi.run(:viewer_states, fn _, %{unset_article_author_upvoted: comment} ->
        viewer_has_upvoted = Enum.member?(comment.meta.upvoted_user_ids, user_id)
        viewer_has_reported = Enum.member?(comment.meta.reported_user_ids, user_id)

        comment
        |> Map.merge(%{viewer_has_upvoted: viewer_has_upvoted})
        |> Map.merge(%{viewer_has_reported: viewer_has_reported})
        |> done
      end)
      |> Multi.run(:sync_embed_replies, fn _, %{viewer_states: comment} ->
        sync_embed_replies(comment)
      end)
      |> Multi.run(:after_hooks, fn _, _ ->
        Later.run({Hooks.Notify, :handle, [:undo, :upvote, comment, from_user]})
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  @doc "lock comment of a article"
  def lock_article_comments(thread, id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id) do
      article_meta = ensure(article.meta, @default_article_meta)
      meta = Map.merge(article_meta, %{is_comment_locked: true})

      ORM.update_meta(article, meta)
    end
  end

  @doc "undo lock comment of a article"
  def undo_lock_article_comments(thread, id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, id) do
      article_meta = ensure(article.meta, @default_article_meta)
      meta = Map.merge(article_meta, %{is_comment_locked: false})

      ORM.update_meta(article, meta)
    end
  end

  # do (un)fold and update folded count in article meta
  defp do_fold_comment(%Comment{} = comment, is_folded) when is_boolean(is_folded) do
    Multi.new()
    |> Multi.run(:fold_comment, fn _, _ ->
      comment |> ORM.update(%{is_folded: is_folded})
    end)
    |> Multi.run(:update_article_fold_count, fn _, _ ->
      {:ok, article} = article_of(comment)
      {:ok, article_thread} = thread_of(article)

      {:ok, %{total_count: total_count}} =
        CMS.paged_folded_comments(article_thread, article.id, %{page: 1, size: 1})

      meta = article.meta |> Map.put(:folded_comment_count, total_count)
      article |> ORM.update_meta(meta)
    end)
    |> Repo.transaction()
    |> result()
  end

  defp update_article_author_upvoted_info(%Comment{} = comment, user_id) do
    with {:ok, article} = get_full_comment(comment.id) do
      is_article_author_upvoted = article.author.id == user_id
      meta = comment.meta |> Map.put(:is_article_author_upvoted, is_article_author_upvoted)
      comment |> ORM.update_meta(meta)
    end
  end

  # 设计盖楼只保留一个层级，回复楼中的评论都会被放到顶楼的 replies 中
  defp get_parent_comment(%Comment{reply_to_id: nil} = comment), do: comment

  defp get_parent_comment(%Comment{reply_to_id: reply_to_id} = comment)
       when not is_nil(reply_to_id) do
    get_parent_comment(Repo.preload(comment.reply_to, reply_to: :author))
  end

  # 如果 replies 没有达到 @max_parent_replies_count, 则添加
  # "加载更多" 的逻辑使用另外的 paged 接口从 CommentReply 表中查询
  defp add_replies_ifneed(
         %Comment{replies: replies} = parent_comment,
         %Comment{} = replyed_comment
       )
       when length(replies) < @max_parent_replies_count do
    new_replies =
      replies
      |> List.insert_at(length(replies), replyed_comment)
      |> Enum.slice(0, @max_parent_replies_count)

    ORM.update_embed(parent_comment, :replies, new_replies)
  end

  # 如果已经有 @max_parent_replies_count 以上的回复了，直接忽略即可
  defp add_replies_ifneed(%Comment{} = parent_comment, _) do
    {:ok, parent_comment}
  end

  defp get_article(%Comment{} = comment) do
    with article_thread <- find_comment_article_thread(comment),
         {:ok, info} <- match(article_thread),
         article_id <- Map.get(comment, info.foreign_key),
         {:ok, article} <- ORM.find(info.model, article_id, preload: [author: :user]) do
      {article_thread, article}
    end
  end

  @spec get_full_comment(String.t()) :: {:ok, T.article_info()} | {:error, nil}
  defp get_full_comment(comment_id) do
    query = from(c in Comment, where: c.id == ^comment_id, preload: ^@article_threads)

    with {:ok, comment} <- Repo.one(query) |> done(),
         article_thread <- find_comment_article_thread(comment) do
      do_extract_article_info(article_thread, Map.get(comment, article_thread))
    end
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

  defp find_comment_article_thread(%Comment{} = comment) do
    @article_threads
    |> Enum.filter(&Map.get(comment, :"#{&1}_id"))
    |> List.first()
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

  defp result({:ok, %{create_comment: result}}), do: {:ok, result}
  defp result({:ok, %{inc_replies_count: result}}), do: {:ok, result}
  defp result({:ok, %{sync_embed_replies: result}}), do: {:ok, result}
  defp result({:ok, %{update_comment_flag: result}}), do: {:ok, result}
  defp result({:ok, %{delete_comment: result}}), do: {:ok, result}
  defp result({:ok, %{fold_comment: result}}), do: {:ok, result}

  defp result({:error, :create_comment, _result, _steps}) do
    raise_error(:create_comment, "create comment error")
  end

  defp result({:error, :create_comment_upvote, _result, _steps}) do
    raise_error(:comment_already_upvote, "already upvoted")
  end

  defp result({:error, :add_participator, result, _steps}) do
    {:error, result}
  end

  defp result({:error, :create_abuse_report, result, _steps}) do
    {:error, result}
  end

  defp result({:error, _, result, _steps}), do: {:error, result}
end
