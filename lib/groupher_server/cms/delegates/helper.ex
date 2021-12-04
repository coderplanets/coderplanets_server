defmodule GroupherServer.CMS.Delegate.Helper do
  @moduledoc """
  helpers for GroupherServer.CMS.Delegate
  """
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher
  import ShortMaps
  import Helper.Utils, only: [get_config: 2, done: 1, strip_struct: 1]

  alias Helper.{ORM, QueryBuilder}
  alias GroupherServer.{Accounts, Repo, CMS}

  alias CMS.Model.{ArticleUpvote, ArticleCollect, Comment}
  alias Accounts.Model.User

  @default_article_meta CMS.Model.Embeds.ArticleMeta.default_meta()
  @max_latest_upvoted_users_count get_config(:article, :max_upvoted_users_count)

  # TODO:
  # @max_latest_emotion_users_count Comment.max_latest_emotion_users_count()
  @max_latest_emotion_users_count 4
  @supported_emotions get_config(:article, :emotions)
  @supported_comment_emotions get_config(:article, :comment_emotions)

  def preload_author(%Comment{} = comment), do: Repo.preload(comment, :author) |> done
  def preload_author(article), do: Repo.preload(article, author: :user) |> done

  @doc "get author of article or comment"
  def author_of(%Comment{} = comment) do
    case Ecto.assoc_loaded?(comment.author) do
      true -> comment.author
      false -> Repo.preload(comment, :author) |> Map.get(:author)
    end
    |> done
  end

  def author_of(article) do
    case Ecto.assoc_loaded?(article.author) do
      true -> article.author.user
      false -> Repo.preload(article, author: :user) |> get_in([:author, :user])
    end
    |> done
  end

  @doc "get parent article of a comment"
  def article_of(%Comment{} = comment) do
    with {:ok, article_thread} <- thread_of(comment) do
      comment |> Repo.preload(article_thread) |> Map.get(article_thread) |> done
    end
  end

  def article_of(_), do: {:error, "only support comment"}

  # get thread of comment
  def thread_of(%Comment{thread: thread}) do
    thread |> String.downcase() |> String.to_atom() |> done
  end

  # get thread of article
  def thread_of(%{meta: %{thread: thread}}) do
    thread |> String.downcase() |> String.to_atom() |> done
  end

  def thread_of(_), do: {:error, "invalid article"}

  def thread_of(%{meta: %{thread: thread}}, :upcase) do
    thread |> to_string |> String.upcase() |> done
  end

  #######
  # emotion related
  #######

  def mark_viewer_emotion_states(paged_artiments, nil), do: paged_artiments
  def mark_viewer_emotion_states(%{entries: []} = paged_artiments, _), do: paged_artiments

  @doc """
  mark viewer emotions status for article or comment
  """
  def mark_viewer_emotion_states(%{entries: entries} = artiments, %User{} = user) do
    entries =
      Enum.map(entries, fn artiment ->
        case Map.has_key?(artiment, :replies) do
          true ->
            mark_viewer_emotion_states(artiment, user)
            |> Map.put(:replies, mark_replies_emotion_states(artiment, user))

          false ->
            mark_viewer_emotion_states(artiment, user)
        end
      end)

    %{artiments | entries: entries}
  end

  def mark_viewer_emotion_states(%Comment{} = comment, %User{} = user) do
    do_mark_viewer_emotion_states(comment, user, @supported_comment_emotions)
  end

  def mark_viewer_emotion_states(article, %User{} = user) do
    do_mark_viewer_emotion_states(article, user, @supported_emotions)
  end

  defp do_mark_viewer_emotion_states(%{emotions: nil} = artiment, _user, _emotions) do
    artiment
  end

  defp do_mark_viewer_emotion_states(artiment, %User{} = user, emotions) do
    update_viewed_status =
      emotions
      |> Enum.reduce([], fn emotion, acc ->
        already_emotioned = user_in_logins?(artiment.emotions[:"#{emotion}_user_logins"], user)
        acc ++ ["viewer_has_#{emotion}ed": already_emotioned]
      end)
      |> Enum.into(%{})

    updated_emotions = Map.merge(artiment.emotions, update_viewed_status)

    %{artiment | emotions: updated_emotions}
  end

  defp mark_replies_emotion_states(%Comment{replies: []}, _), do: []

  defp mark_replies_emotion_states(%Comment{replies: replies}, user) do
    Enum.map(replies, fn reply_comment ->
      mark_viewer_emotion_states(reply_comment, user)
    end)
  end

  @doc """
  update emotions field for boty article and comment
  """
  def update_emotions_field(artiment, emotion, status, user) do
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

    artiment |> ORM.update_embed(:emotions, emotions)
  end

  def sync_embed_replies(%Comment{reply_to_id: nil} = comment) do
    {:ok, comment}
  end

  # replies(embed_many) 不会自定更新，需要手动更新，否则在 replies 模式下数据会不同步。
  def sync_embed_replies(%Comment{reply_to_id: reply_to_id} = comment) do
    with {:ok, parent_comment} <- ORM.find(Comment, reply_to_id),
         embed_index <- Enum.find_index(parent_comment.replies, &(&1.id == comment.id)) do
      case is_nil(embed_index) do
        true ->
          {:ok, comment}

        false ->
          replies = List.replace_at(parent_comment.replies, embed_index, comment)

          # 理论上更新一次即可，但 Changeset 无法识别数量一致的 replies ，不确定是业务代码的问题还是 Ecto 的问题，好坑啊
          {:ok, parent_comment} = ORM.update_embed(parent_comment, :replies, [])
          {:ok, _} = ORM.update_embed(parent_comment, :replies, replies)
      end

      {:ok, comment}
    end
  end

  defp user_in_logins?([], _), do: false
  defp user_in_logins?(ids_list, %User{login: login}), do: Enum.member?(ids_list, login)

  #######
  # emotion related end
  #######

  ######
  # reaction related end, include upvote && collect
  #######
  @doc """
  paged [reaction] users list
  """
  def load_reaction_users(queryable, thread, article_id, filter) do
    %{page: page, size: size} = filter

    with {:ok, info} <- match(thread) do
      queryable
      |> where([u], field(u, ^info.foreign_key) == ^article_id)
      |> QueryBuilder.load_inner_users(filter)
      |> ORM.paginator(~m(page size)a)
      |> done()
    end
  end

  @doc """
  update the [reaction]s_count for article
  e.g:
  inc/dec upvotes_count of article
  """
  def update_article_reactions_count(info, article, field, opt) do
    schema =
      case field do
        :upvotes_count -> ArticleUpvote
        :collects_count -> ArticleCollect
      end

    {:ok, cur_count} =
      from(u in schema, where: field(u, ^info.foreign_key) == ^article.id) |> ORM.count()

    case opt do
      :inc ->
        new_count = Enum.max([0, cur_count])
        ORM.update(article, Map.put(%{}, field, new_count + 1))

      :dec ->
        new_count = Enum.max([1, cur_count])
        ORM.update(article, Map.put(%{}, field, new_count - 1))
    end
  end

  @doc """
  add or remove artilce's reaction users is list history
  e.g:
  add/remove user_id to upvoted_user_ids in article meta
  """
  @spec update_article_reaction_user_list(
          :upvot | :collect,
          T.article_common(),
          User.t(),
          :add | :remove
        ) :: T.article_common()
  def update_article_reaction_user_list(action, %{meta: nil} = article, %User{} = user, opt) do
    cur_user_ids = []
    cur_users = []

    updated_user_ids =
      case opt do
        :add -> [user.id] ++ cur_user_ids
        :remove -> cur_user_ids -- [user.id]
      end

    updated_users =
      case opt do
        :add -> [extract_embed_user(user)] ++ cur_users
        :remove -> Enum.reject(cur_users, &(&1.user_id == user.id))
      end

    meta =
      @default_article_meta
      |> Map.merge(%{"#{action}ed_user_ids": updated_user_ids})
      |> Map.merge(%{"latest_#{action}ed_users": updated_users})

    ORM.update_meta(article, meta)
  end

  def update_article_reaction_user_list(action, article, %User{} = user, opt) do
    cur_user_ids = get_in(article, [:meta, :"#{action}ed_user_ids"])

    cur_users =
      get_in(article, [:meta, :"latest_#{action}ed_users"]) |> Enum.map(&strip_struct(&1))

    updated_user_ids =
      case opt do
        :add -> [user.id] ++ cur_user_ids
        :remove -> cur_user_ids -- [user.id]
      end

    updated_users =
      case opt do
        :add -> [extract_embed_user(user)] ++ cur_users
        :remove -> Enum.reject(cur_users, &(&1.user_id == user.id))
      end
      |> Enum.uniq()
      |> Enum.slice(0, @max_latest_upvoted_users_count)

    meta =
      article.meta
      |> Map.merge(%{"#{action}ed_user_ids": updated_user_ids})
      |> Map.merge(%{"latest_#{action}ed_users": updated_users})

    ORM.update_meta(article, meta)
  end

  defp extract_embed_user(%User{} = user) do
    %{
      user_id: user.id,
      avatar: user.avatar,
      login: user.login,
      nickname: user.nickname
    }
  end
end
