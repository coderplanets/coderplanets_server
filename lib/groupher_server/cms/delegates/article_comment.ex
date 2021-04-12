defmodule GroupherServer.CMS.Delegate.ArticleComment do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]

  import ShortMaps

  alias Helper.{ORM, QueryBuilder}
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{ArticleComment, ArticleCommentUpvote, ArticleCommentReply, Post, Job}
  alias Ecto.Multi

  # the limit of latest participators stored in article's comment_participator
  @max_participator_count 5
  @max_replies_count 5

  @doc """
  list paged article comments
  """
  def list_article_comments(thread, article_id, %{page: page, size: size} = filters) do
    with {:ok, thread_query} <- match(thread, :query, article_id) do
      ArticleComment
      |> where(^thread_query)
      |> QueryBuilder.filter_pack(filters)
      |> ORM.paginater(~m(page size)a)
      |> done()
    end
  end

  defp match(:post, :query, id), do: {:ok, dynamic([c], c.post_id == ^id)}
  defp match(:job, :query, id), do: {:ok, dynamic([c], c.job_id == ^id)}

  @doc """
  Creates a comment for psot, job ...
  """
  def write_comment(
        thread,
        article_id,
        content,
        %User{id: user_id} = user
      ) do
    with {:ok, info} <- match(thread),
         # make sure the article exsit
         # author is passed by middleware, it's exsit for sure
         {:ok, article} <- ORM.find(info.model, article_id) do
      Multi.new()
      |> Multi.run(:write_comment, fn _, _ ->
        args = %{author_id: user_id, body_html: content} |> Map.put(info.foreign_key, article.id)
        ArticleComment |> ORM.create(args)
      end)
      |> Multi.run(:add_participator, fn _, _ ->
        add_participator_to_article(article, user)
      end)
      # |> Multi.run(:mention_users, fn _, %{create_comment: comment} ->
      #   Delivery.mention_from_comment(community, thread, content, comment, args, user)
      #   {:ok, :pass}
      # end)
      |> Repo.transaction()
      |> write_comment_result()
    end
  end

  def upvote_comment(comment_id, %User{id: user_id}) do
    # make sure the comment exsit
    # TODO: make sure the comment is not deleted yet
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id) do
      args = %{article_comment_id: comment.id, user_id: user_id}
      ArticleCommentUpvote |> ORM.create(args)
    end
  end

  def reply_article_comment(
        comment_id,
        content,
        %User{id: user_id}
      ) do
    with {:ok, replying_comment} <- ORM.find(ArticleComment, comment_id, preload: :reply_to),
         reply_args <-
           Map.put(%{author_id: user_id, body_html: content}, :post_id, replying_comment.post_id) do
      # create reply
      {:ok, replyed_comment} = ORM.create(ArticleComment, reply_args)

      ArticleCommentReply
      |> ORM.create(%{article_comment_id: replyed_comment.id, reply_to_id: replying_comment.id})

      # IO.inspect(replying_comment, label: "hello replying_comment")
      # 只有一个缩进层级
      parent_comment = get_parent_comment(replying_comment)
      # IO.inspect(parent_comment, label: "after")
      # if is_nil(replying_comment.reply_to),
      #   do: replying_comment,
      #   else: replying_comment.reply_to

      # IO.inspect(parent_comment, label: ">> parent_comment")

      add_replies_ifneed(parent_comment, replyed_comment)

      replyed_comment
      |> Repo.preload(:reply_to)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:reply_to, replying_comment)
      |> Repo.update()
    end
  end

  # 设计盖楼只有一层，回复楼中的评论都会被放到顶楼的 replies 中
  defp get_parent_comment(%ArticleComment{reply_to_id: nil} = comment) do
    comment
  end

  defp get_parent_comment(%ArticleComment{reply_to_id: reply_to_id} = comment) do
    Repo.preload(comment, :reply_to) |> Map.get(:reply_to)
    # get_parent_comment(Repo.preload(comment, :reply_to))
  end

  defp add_replies_ifneed(
         %ArticleComment{replies: replies} = parent_comment,
         %ArticleComment{} = replyed_comment
       )
       when length(replies) < @max_replies_count do
    new_replies =
      replies
      |> List.insert_at(length(replies), replyed_comment)
      |> Enum.slice(0, @max_replies_count)

    parent_comment
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:replies, new_replies)
    |> Repo.update()
  end

  defp add_replies_ifneed(%ArticleComment{} = parent_comment, _) do
    {:ok, parent_comment}
  end

  defp write_comment_result({:ok, %{write_comment: result}}), do: {:ok, result}

  defp write_comment_result({:error, :create_comment, result, _steps}) do
    {:error, result}
  end

  defp write_comment_result({:error, :add_participator, result, _steps}) do
    {:error, result}
  end

  # add participator to article-like content (Post, Job ...)
  defp add_participator_to_article(%Post{} = article, %User{} = user) do
    new_comment_participators =
      article.comment_participators
      |> List.insert_at(0, user)
      |> Enum.uniq()
      |> Enum.slice(0, @max_participator_count)

    article
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:comment_participators, new_comment_participators)
    |> Repo.update()
  end

  defp add_participator_to_article(_, _), do: {:ok, :pass}

  defp match(:post) do
    {:ok, %{model: Post, foreign_key: :post_id}}
  end

  defp match(:job) do
    {:ok, %{model: Job, foreign_key: :job_id}}
  end

  # defp do_create_comment(thread, action, content, body, user) do
  #   next_floor = get_next_floor(thread, action.reactor, content.id)

  #   attrs = %{
  #     author_id: user.id,
  #     body: body,
  #     floor: next_floor
  #   }

  #   attrs = merge_comment_attrs(thread, attrs, content.id)

  #   action.reactor |> ORM.create(attrs)
  # end
end
