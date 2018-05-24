defmodule MastaniServer.CMS.Delegate.CommentCURD do
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import MastaniServer.CMS.Utils.Matcher

  alias MastaniServer.{Repo, Accounts}
  alias Helper.{ORM, QueryBuilder}
  alias MastaniServer.CMS.{PostCommentReply, JobCommentReply}

  @doc """
  Creates a comment for psot, job ...
  """
  # TODO: remove react
  def create_comment(part, part_id, %Accounts.User{id: user_id}, body) do
    with {:ok, action} <- match_action(part, :comment),
         {:ok, content} <- ORM.find(action.target, part_id),
         {:ok, user} <- ORM.find(Accounts.User, user_id) do
      # TODO: refactor
      nextFloor =
        case part do
          :post ->
            action.reactor
            |> where([c], c.post_id == ^content.id)
            |> ORM.next_count()

          :job ->
            action.reactor
            |> where([c], c.job_id == ^content.id)
            |> ORM.next_count()
        end

      attrs =
        case part do
          :post ->
            %{post_id: content.id, author_id: user.id, body: body, floor: nextFloor}

          :job ->
            %{job_id: content.id, author_id: user.id, body: body, floor: nextFloor}
        end

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
      nextFloor = get_next_floor(part, action.reactor, comment)

      attrs = %{
        author_id: user_id,
        body: body,
        reply_to: comment,
        floor: nextFloor
      }

      attrs =
        case part do
          :post ->
            attrs |> Map.merge(%{post_id: comment.post_id})

          :job ->
            attrs |> Map.merge(%{job_id: comment.job_id})
        end

      brige_reply(part, action.reactor, comment, attrs)
    end
  end

  defp brige_reply(:post, queryable, comment, attrs) do
    # TODO: use Multi task to refactor
    with {:ok, reply} <- ORM.create(queryable, attrs) do
      ORM.update(reply, %{reply_id: comment.id})

      {:ok, _} =
        PostCommentReply |> ORM.create(%{post_comment_id: comment.id, reply_id: reply.id})

      queryable |> ORM.find(reply.id)
    end
  end

  defp brige_reply(:job, queryable, comment, attrs) do
    # TODO: use Multi task to refactor
    with {:ok, reply} <- ORM.create(queryable, attrs) do
      ORM.update(reply, %{reply_id: comment.id})

      {:ok, _} = JobCommentReply |> ORM.create(%{job_comment_id: comment.id, reply_id: reply.id})

      queryable |> ORM.find(reply.id)
    end
  end

  defp get_next_floor(part, queryable, comment) do
    dynamic =
      case part do
        :post ->
          dynamic([c], c.post_id == ^comment.post_id)

        :job ->
          dynamic([c], c.job_id == ^comment.job_id)
      end

    queryable
    |> where(^dynamic)
    |> ORM.next_count()
  end
end
