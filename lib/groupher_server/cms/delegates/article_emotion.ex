defmodule GroupherServer.CMS.Delegate.ArticleEmotion do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher

  import GroupherServer.CMS.Delegate.Helper, only: [update_emotions_field: 4]

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.Model.User
  alias CMS.Model.{ArticleUserEmotion}

  alias Ecto.Multi

  @type t_user_list :: [%{login: String.t()}]
  @type t_mention_status :: %{user_list: t_user_list, user_count: Integer.t()}

  @doc "make emotion to a comment"
  def emotion_to_article(thread, article_id, emotion, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: :author) do
      Multi.new()
      |> Multi.run(:create_user_emotion, fn _, _ ->
        target =
          %{recived_user_id: article.author.user_id, user_id: user.id}
          |> Map.put(info.foreign_key, article_id)

        args = Map.put(target, :"#{emotion}", true)

        case ORM.find_by(ArticleUserEmotion, target) do
          {:ok, article_user_emotion} -> ORM.update(article_user_emotion, args)
          {:error, _} -> ORM.create(ArticleUserEmotion, args)
        end
      end)
      |> Multi.run(:query_emotion_status, fn _, _ ->
        query_emotion_status(thread, article.id, emotion)
      end)
      |> Multi.run(:update_emotions_field, fn _, %{query_emotion_status: status} ->
        update_emotions_field(article, emotion, status, user)
      end)
      |> Repo.transaction()
      |> update_emotions_field_result
    end
  end

  def undo_emotion_to_article(thread, article_id, emotion, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: :author) do
      Multi.new()
      |> Multi.run(:update_user_emotion, fn _, _ ->
        target =
          %{recived_user_id: article.author.user_id, user_id: user.id}
          |> Map.put(info.foreign_key, article_id)

        case ORM.find_by(ArticleUserEmotion, target) do
          {:ok, article_user_emotion} ->
            args = Map.put(target, :"#{emotion}", false)
            article_user_emotion |> ORM.update(args)

          {:error, _} ->
            # args = Map.put(target, :"#{emotion}", false)
            args = target
            ORM.create(ArticleUserEmotion, args)
        end
      end)
      |> Multi.run(:query_emotion_status, fn _, _ ->
        query_emotion_status(thread, article.id, emotion)
      end)
      |> Multi.run(:update_emotions_field, fn _, %{query_emotion_status: status} ->
        update_emotions_field(article, emotion, status, user)
      end)
      |> Repo.transaction()
      |> update_emotions_field_result
    end
  end

  # @spec query_emotion_status(Comment.t(), Atom.t()) :: {:ok, t_mention_status}
  defp query_emotion_status(thread, article_id, emotion) do
    with {:ok, info} <- match(thread) do
      # 每次被 emotion 动作触发后重新查询，主要原因
      # 1.并发下保证数据准确，类似 views 阅读数的统计
      # 2. 前端使用 nickname 而非 login 展示，如果用户改了 nickname, 可以"自动纠正"
      query =
        from(a in ArticleUserEmotion,
          join: user in User,
          on: a.user_id == user.id,
          where: field(a, ^info.foreign_key) == ^article_id,
          where: field(a, ^emotion) == true,
          select: %{login: user.login, nickname: user.nickname}
        )

      emotioned_user_info_list = Repo.all(query) |> Enum.uniq()
      emotioned_user_count = length(emotioned_user_info_list)

      {:ok, %{user_list: emotioned_user_info_list, user_count: emotioned_user_count}}
    end
  end

  defp update_emotions_field_result({:ok, %{update_emotions_field: result}}), do: {:ok, result}

  defp update_emotions_field_result({:error, _, result, _steps}) do
    {:error, result}
  end
end
