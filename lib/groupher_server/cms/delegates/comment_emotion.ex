defmodule GroupherServer.CMS.Delegate.CommentEmotion do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false

  import Helper.Utils, only: [done: 1]

  import GroupherServer.CMS.Delegate.Helper,
    only: [
      update_emotions_field: 4,
      mark_viewer_emotion_states: 2,
      sync_embed_replies: 1
    ]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.Model.User
  alias CMS.Model.{Comment, CommentUserEmotion}

  alias Ecto.Multi

  @type t_user_list :: [%{login: String.t()}]
  @type t_mention_status :: %{user_list: t_user_list, user_count: Integer.t()}

  @doc "make emotion to a comment"
  def emotion_to_comment(comment_id, emotion, %User{} = user) do
    with {:ok, comment} <- ORM.find(Comment, comment_id, preload: :author) do
      Multi.new()
      |> Multi.run(:create_user_emotion, fn _, _ ->
        target = %{
          comment_id: comment.id,
          recived_user_id: comment.author.id,
          user_id: user.id
        }

        args = Map.put(target, :"#{emotion}", true)

        case ORM.find_by(CommentUserEmotion, target) do
          {:ok, comment_user_emotion} -> ORM.update(comment_user_emotion, args)
          {:error, _} -> ORM.create(CommentUserEmotion, args)
        end
      end)
      |> Multi.run(:query_emotion_states, fn _, _ ->
        query_emotion_states(comment, emotion)
      end)
      |> Multi.run(:update_emotions_field, fn _, %{query_emotion_states: status} ->
        with {:ok, comment} <- update_emotions_field(comment, emotion, status, user),
             {:ok, comment} <- sync_embed_replies(comment) do
          mark_viewer_emotion_states(comment, user) |> done
        end
      end)
      |> Repo.transaction()
      |> result
    end
  end

  def undo_emotion_to_comment(comment_id, emotion, %User{} = user) do
    with {:ok, comment} <- ORM.find(Comment, comment_id, preload: :author) do
      Multi.new()
      |> Multi.run(:update_user_emotion, fn _, _ ->
        target = %{
          comment_id: comment.id,
          recived_user_id: comment.author.id,
          user_id: user.id
        }

        case ORM.find_by(CommentUserEmotion, target) do
          {:ok, comment_user_emotion} ->
            args = Map.put(target, :"#{emotion}", false)
            comment_user_emotion |> ORM.update(args)

          {:error, _} ->
            ORM.create(CommentUserEmotion, target)
        end
      end)
      |> Multi.run(:query_emotion_states, fn _, _ ->
        query_emotion_states(comment, emotion)
      end)
      |> Multi.run(:update_emotions_field, fn _, %{query_emotion_states: status} ->
        with {:ok, comment} <- update_emotions_field(comment, emotion, status, user) do
          mark_viewer_emotion_states(comment, user) |> done
        end
      end)
      |> Repo.transaction()
      |> result
    end
  end

  @spec query_emotion_states(Comment.t(), Atom.t()) :: {:ok, t_mention_status}
  defp query_emotion_states(comment, emotion) do
    # 每次被 emotion 动作触发后重新查询，主要原因
    # 1.并发下保证数据准确，类似 views 阅读数的统计
    # 2. 前端使用 nickname 而非 login 展示，如果用户改了 nickname, 可以"自动纠正"
    query =
      from(a in CommentUserEmotion,
        join: user in User,
        on: a.user_id == user.id,
        where: a.comment_id == ^comment.id,
        where: field(a, ^emotion) == true,
        select: %{login: user.login, nickname: user.nickname}
      )

    emotioned_user_info_list = Repo.all(query) |> Enum.uniq()
    emotioned_user_count = length(emotioned_user_info_list)

    {:ok, %{user_list: emotioned_user_info_list, user_count: emotioned_user_count}}
  end

  defp result({:ok, %{update_emotions_field: result}}), do: {:ok, result}

  defp result({:error, _, result, _steps}) do
    {:error, result}
  end
end
