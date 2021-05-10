defmodule GroupherServer.CMS.Delegate.ArticleEmotion do
  @moduledoc """
  CURD and operations for article comments
  """
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher2

  alias Helper.ORM
  alias GroupherServer.{Accounts, CMS, Repo}

  alias Accounts.User
  alias CMS.{ArticleUserEmotion}

  alias Ecto.Multi

  @type t_user_list :: [%{login: String.t()}]
  @type t_mention_status :: %{user_list: t_user_list, user_count: Integer.t()}

  # ArticleComment.max_latest_emotion_users_count()
  @max_latest_emotion_users_count 4

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
          {:ok, article_user_emotion} -> article_user_emotion |> ORM.update(args)
          {:error, _} -> ArticleUserEmotion |> ORM.create(args)
        end
      end)
      |> Multi.run(:query_emotion_status, fn _, _ ->
        query_emotion_status(thread, article.id, emotion)
      end)
      |> Multi.run(:update_emotion, fn _, %{query_emotion_status: status} ->
        update_emotion(article, emotion, status, user)
      end)
      |> Repo.transaction()
      |> update_emotion_result
    end
  end

  def undo_emotion_to_article(thread, article_id, emotion, %User{} = user) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: :author) do
      Multi.new()
      |> Multi.run(:update_user_emotion, fn _, _ ->
        target =
          %{recived_user_id: article.author.id, user_id: user.id}
          |> Map.put(info.foreign_key, article_id)

        {:ok, article_user_emotion} = ORM.find_by(ArticleUserEmotion, target)
        args = Map.put(target, :"#{emotion}", false)
        article_user_emotion |> ORM.update(args)
      end)
      |> Multi.run(:query_emotion_status, fn _, _ ->
        query_emotion_status(thread, article.id, emotion)
      end)
      |> Multi.run(:update_emotion, fn _, %{query_emotion_status: status} ->
        update_emotion(article, emotion, status, user)
      end)
      |> Repo.transaction()
      |> update_emotion_result
    end
  end

  # @spec query_emotion_status(ArticleComment.t(), Atom.t()) :: {:ok, t_mention_status}
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

  @spec update_emotion(ArticleComment.t(), Atom.t(), t_mention_status, User.t()) ::
          {:ok, ArticleComment.t()} | {:error, any}
  defp update_emotion(comment, emotion, status, user) do
    %{user_count: user_count, user_list: user_list} = status

    emotions =
      %{}
      |> Map.put(:"#{emotion}_count", user_count)
      |> Map.put(:"#{emotion}_user_logins", user_list |> Enum.map(& &1.login))
      |> Map.put(
        :"latest_#{emotion}_users",
        Enum.slice(user_list, 0, @max_latest_emotion_users_count)
      )

    viewer_has_emotioned = user.login in Map.get(emotions, :"#{emotion}_user_logins")
    emotions = emotions |> Map.put(:"viewer_has_#{emotion}ed", viewer_has_emotioned)

    comment
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:emotions, emotions)
    |> Repo.update()
    # virtual field can not be updated
    |> add_viewer_emotioned_ifneed(emotions)
  end

  defp add_viewer_emotioned_ifneed({:error, error}, _), do: {:error, error}

  defp add_viewer_emotioned_ifneed({:ok, comment}, emotions) do
    # Map.merge(comment, %{emotion: emotions})
    {:ok, Map.merge(comment, %{emotion: emotions})}
  end

  defp update_emotion_result({:ok, %{update_emotion: result}}), do: {:ok, result}

  defp update_emotion_result({:error, _, result, _steps}) do
    {:error, result}
  end
end
