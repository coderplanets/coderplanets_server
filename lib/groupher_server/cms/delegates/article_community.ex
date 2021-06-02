defmodule GroupherServer.CMS.Delegate.ArticleCommunity do
  @moduledoc """
  set / unset operations for Article-like resource
  """
  import GroupherServer.CMS.Helper.Matcher
  import Ecto.Query, warn: false

  import Helper.ErrorCode
  import Helper.Utils, only: [strip_struct: 1, done: 1]
  import GroupherServer.CMS.Helper.Matcher

  alias Helper.Types, as: T
  alias Helper.ORM

  alias GroupherServer.CMS.{Embeds, Community, PinnedArticle}
  alias GroupherServer.Repo

  alias Ecto.Multi

  @default_article_meta Embeds.ArticleMeta.default_meta()
  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  @spec pin_article(T.article_thread(), Integer.t(), Integer.t()) :: {:ok, PinnedArticle.t()}
  def pin_article(thread, article_id, community_id) do
    with {:ok, info} <- match(thread),
         args <- pack_pin_args(thread, article_id, community_id),
         {:ok, _} <- check_pinned_article_count(args.community_id, thread),
         {:ok, _} <- ORM.create(PinnedArticle, args) do
      ORM.find(info.model, article_id)
    end
  end

  @spec undo_pin_article(T.article_thread(), Integer.t(), Integer.t()) :: {:ok, PinnedArticle.t()}
  def undo_pin_article(thread, article_id, community_id) do
    with {:ok, info} <- match(thread),
         args <- pack_pin_args(thread, article_id, community_id) do
      ORM.findby_delete(PinnedArticle, args)
      ORM.find(info.model, article_id)
    end
  end

  defp pack_pin_args(thread, article_id, community_id) do
    with {:ok, info} <- match(thread),
         {:ok, community} <- ORM.find(Community, community_id) do
      thread_upcase = thread |> to_string |> String.upcase()

      Map.put(
        %{community_id: community.id, thread: thread_upcase},
        info.foreign_key,
        article_id
      )
    end
  end

  ########
  ########
  ########

  @doc """
  mirror article to other community
  """
  def mirror_article(thread, article_id, community_id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <- ORM.find(info.model, article_id, preload: :communities),
         {:ok, community} <- ORM.find(Community, community_id) do
      article
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:communities, article.communities ++ [community])
      |> Repo.update()
    end
  end

  @doc """
  unmirror article to a community
  """
  def unmirror_article(thread, article_id, community_id) do
    with {:ok, info} <- match(thread),
         {:ok, article} <-
           ORM.find(info.model, article_id, preload: [:communities, :original_community]),
         {:ok, community} <- ORM.find(Community, community_id) do
      case article.original_community.id == community.id do
        true ->
          raise_error(:mirror_article, "can not unmirror original_community")

        false ->
          article
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:communities, article.communities -- [community])
          |> Repo.update()
      end
    end
  end

  @doc """
  move article original community to other community
  """
  def move_article(thread, article_id, community_id) do
    with {:ok, info} <- match(thread),
         {:ok, community} <- ORM.find(Community, community_id),
         {:ok, article} <-
           ORM.find(info.model, article_id, preload: [:communities, :original_community]) do
      cur_original_community = article.original_community

      Multi.new()
      |> Multi.run(:change_original_community, fn _, _ ->
        article
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:original_community_id, community.id)
        |> Repo.update()
      end)
      |> Multi.run(:unmirror_article, fn _, %{change_original_community: article} ->
        article
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:communities, article.communities -- [cur_original_community])
        |> Repo.update()
      end)
      |> Multi.run(:mirror_target_community, fn _, %{unmirror_article: article} ->
        article
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:communities, article.communities ++ [community])
        |> Repo.update()
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  defp result({:ok, %{mirror_target_community: result}}), do: result |> done()
  defp result({:error, _, result, _steps}), do: {:error, result}

  @doc "update isEdited meta label if needed"
  # TODO: diff history
  def update_edit_status(%{meta: %Embeds.ArticleMeta{is_edited: false} = meta} = content) do
    meta = meta |> strip_struct |> Map.merge(%{is_edited: true})
    ORM.update_meta(content, meta)
  end

  # for test or exsiting articles
  def update_edit_status(%{meta: nil} = content) do
    meta = Embeds.ArticleMeta.default_meta() |> Map.merge(%{is_edited: true})

    ORM.update_meta(content, meta)
  end

  def update_edit_status(content, _), do: {:ok, content}

  # check if the thread has aready enough pinned articles
  defp check_pinned_article_count(community_id, thread) do
    thread_upcase = thread |> to_string |> String.upcase()

    query =
      from(p in PinnedArticle,
        where: p.community_id == ^community_id and p.thread == ^thread_upcase
      )

    pinned_articles = query |> Repo.all()

    case length(pinned_articles) >= @max_pinned_article_count_per_thread do
      true -> raise_error(:too_much_pinned_article, "too much pinned article")
      _ -> {:ok, :pass}
    end
  end
end
