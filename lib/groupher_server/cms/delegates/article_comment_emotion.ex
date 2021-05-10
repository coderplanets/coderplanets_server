defmodule GroupherServer.CMS.Delegate.ArticleCommentEmotion do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false

  import GroupherServer.CMS.Delegate.Helper, only: [update_emotions_field: 4]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{ArticleComment, ArticleCommentUserEmotion}

  alias Ecto.Multi

  @type t_user_list :: [%{login: String.t()}]
  @type t_mention_status :: %{user_list: t_user_list, user_count: Integer.t()}

  @doc "make emotion to a comment"
  def emotion_to_comment(comment_id, emotion, %User{} = user) do
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id, preload: :author) do
      Multi.new()
      |> Multi.run(:create_user_emotion, fn _, _ ->
        target = %{
          article_comment_id: comment.id,
          recived_user_id: comment.author.id,
          user_id: user.id
        }

        args = Map.put(target, :"#{emotion}", true)

        case ORM.find_by(ArticleCommentUserEmotion, target) do
          {:ok, article_comment_user_emotion} -> ORM.update(article_comment_user_emotion, args)
          {:error, _} -> ORM.create(ArticleCommentUserEmotion, args)
        end
      end)
      |> Multi.run(:query_emotion_states, fn _, _ ->
        query_emotion_states(comment, emotion)
      end)
      |> Multi.run(:update_emotions_field, fn _, %{query_emotion_states: status} ->
        update_emotions_field(comment, emotion, status, user)
      end)
      |> Repo.transaction()
      |> update_emotions_field_result
    end
  end

  def undo_emotion_to_comment(comment_id, emotion, %User{} = user) do
    with {:ok, comment} <- ORM.find(ArticleComment, comment_id, preload: :author) do
      Multi.new()
      |> Multi.run(:update_user_emotion, fn _, _ ->
        target = %{
          article_comment_id: comment.id,
          recived_user_id: comment.author.id,
          user_id: user.id
        }

        {:ok, article_comment_user_emotion} = ORM.find_by(ArticleCommentUserEmotion, target)
        args = Map.put(target, :"#{emotion}", false)
        article_comment_user_emotion |> ORM.update(args)
      end)
      |> Multi.run(:query_emotion_states, fn _, _ ->
        query_emotion_states(comment, emotion)
      end)
      |> Multi.run(:update_emotions_field, fn _, %{query_emotion_states: status} ->
        update_emotions_field(comment, emotion, status, user)
      end)
      |> Repo.transaction()
      |> update_emotions_field_result
    end
  end

  @spec query_emotion_states(ArticleComment.t(), Atom.t()) :: {:ok, t_mention_status}
  defp query_emotion_states(comment, emotion) do
    # 每次被 emotion 动作触发后重新查询，主要原因
    # 1.并发下保证数据准确，类似 views 阅读数的统计
    # 2. 前端使用 nickname 而非 login 展示，如果用户改了 nickname, 可以"自动纠正"
    query =
      from(a in ArticleCommentUserEmotion,
        join: user in User,
        on: a.user_id == user.id,
        where: a.article_comment_id == ^comment.id,
        where: field(a, ^emotion) == true,
        select: %{login: user.login, nickname: user.nickname}
      )

    emotioned_user_info_list = Repo.all(query) |> Enum.uniq()
    emotioned_user_count = length(emotioned_user_info_list)

    {:ok, %{user_list: emotioned_user_info_list, user_count: emotioned_user_count}}
  end

  defp update_emotions_field_result({:ok, %{update_emotions_field: result}}), do: {:ok, result}

  defp update_emotions_field_result({:error, _, result, _steps}) do
    {:error, result}
  end
end
