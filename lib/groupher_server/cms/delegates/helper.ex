defmodule GroupherServer.CMS.Delegate.Helper do
  @moduledoc """
  helpers for GroupherServer.CMS.Delegate
  """
  import Helper.Utils, only: [get_config: 2, done: 1, strip_struct: 1]
  import Ecto.Query, warn: false
  import GroupherServer.CMS.Helper.Matcher
  import ShortMaps

  alias Helper.{ORM, QueryBuilder}
  alias GroupherServer.{Accounts, Repo, CMS}

  alias CMS.Model.{ArticleUpvote, ArticleCollect, Comment}
  alias Accounts.Model.User

  @default_article_meta CMS.Model.Embeds.ArticleMeta.default_meta()

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

  #######
  # emotion related
  #######
  defp get_supported_mentions(:comment), do: @supported_comment_emotions
  defp get_supported_mentions(_), do: @supported_emotions

  def mark_viewer_emotion_states(paged_contents, nil), do: paged_contents
  def mark_viewer_emotion_states(%{entries: []} = paged_contents, _), do: paged_contents
  def mark_viewer_emotion_states(paged_contents, nil, :comment), do: paged_contents

  @doc """
  mark viewer emotions status for article or comment
  """
  def mark_viewer_emotion_states(
        %{entries: entries} = paged_contents,
        %User{} = user,
        type \\ :article
      ) do
    supported_emotions = get_supported_mentions(type)

    new_entries =
      Enum.map(entries, fn article ->
        update_viewed_status =
          supported_emotions
          |> Enum.reduce([], fn emotion, acc ->
            already_emotioned = user_in_logins?(article.emotions[:"#{emotion}_user_logins"], user)
            acc ++ ["viewer_has_#{emotion}ed": already_emotioned]
          end)
          |> Enum.into(%{})

        updated_emotions = Map.merge(article.emotions, update_viewed_status)
        Map.put(article, :emotions, updated_emotions)
      end)

    %{paged_contents | entries: new_entries}
  end

  @doc """
  update emotions field for boty article and comment
  """
  def update_emotions_field(content, emotion, status, user) do
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

    content
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:emotions, emotions)
    |> Repo.update()
    # virtual field can not be updated
    |> add_viewer_emotioned_ifneed(emotions)
    |> done
  end

  defp add_viewer_emotioned_ifneed({:error, error}, _), do: {:error, error}

  defp add_viewer_emotioned_ifneed({:ok, comment}, emotions) do
    Map.merge(comment, %{emotion: emotions})
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
      |> ORM.paginater(~m(page size)a)
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

    count_query = from(u in schema, where: field(u, ^info.foreign_key) == ^article.id)
    cur_count = Repo.aggregate(count_query, :count)

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
          String.t(),
          :add | :remove
        ) :: T.article_common()
  def update_article_reaction_user_list(action, %{meta: nil} = article, user_id, opt) do
    cur_user_ids = []

    updated_user_ids =
      case opt do
        :add -> [user_id] ++ cur_user_ids
        :remove -> cur_user_ids -- [user_id]
      end

    meta = @default_article_meta |> Map.merge(%{"#{action}ed_user_ids": updated_user_ids})
    ORM.update_meta(article, meta)
  end

  def update_article_reaction_user_list(action, article, user_id, opt) do
    cur_user_ids = get_in(article, [:meta, :"#{action}ed_user_ids"])

    updated_user_ids =
      case opt do
        :add -> [user_id] ++ cur_user_ids
        :remove -> cur_user_ids -- [user_id]
      end

    meta = article.meta |> Map.merge(%{"#{action}ed_user_ids": updated_user_ids}) |> strip_struct
    ORM.update_meta(article, meta)
  end
end
