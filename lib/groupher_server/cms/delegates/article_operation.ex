defmodule GroupherServer.CMS.Delegate.ArticleOperation do
  @moduledoc """
  set / unset operations for Article-like resource
  """
  import GroupherServer.CMS.Helper.Matcher
  import Ecto.Query, warn: false

  import Helper.ErrorCode
  import ShortMaps
  import Helper.Utils, only: [strip_struct: 1]
  import GroupherServer.CMS.Helper.Matcher2

  alias Helper.Types, as: T
  alias Helper.ORM

  alias GroupherServer.CMS.{
    Embeds,
    Community,
    Post,
    PostCommunityFlag,
    Job,
    JobCommunityFlag,
    RepoCommunityFlag,
    Tag,
    PinnedArticle
  }

  alias GroupherServer.CMS.Repo, as: CMSRepo
  alias GroupherServer.Repo

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
  ########
  ########

  @doc """
  trash / untrash articles
  """
  def set_community_flags(%Community{id: cid}, content, attrs) do
    with {:ok, content} <- ORM.find(content.__struct__, content.id),
         {:ok, record} <- insert_flag_record(content, cid, attrs) do
      {:ok, struct(content, %{trash: record.trash})}
    end
  end

  def set_community_flags(community_id, content, attrs) do
    with {:ok, content} <- ORM.find(content.__struct__, content.id),
         {:ok, community} <- ORM.find(Community, community_id),
         {:ok, record} <- insert_flag_record(content, community.id, attrs) do
      {:ok, struct(content, %{trash: record.trash})}
    end
  end

  defp insert_flag_record(%Post{id: post_id}, community_id, attrs) do
    clauses = ~m(post_id community_id)a
    PostCommunityFlag |> ORM.upsert_by(clauses, Map.merge(attrs, clauses))
  end

  defp insert_flag_record(%Job{id: job_id}, community_id, attrs) do
    clauses = ~m(job_id community_id)a
    JobCommunityFlag |> ORM.upsert_by(clauses, Map.merge(attrs, clauses))
  end

  defp insert_flag_record(%CMSRepo{id: repo_id}, community_id, attrs) do
    clauses = ~m(repo_id community_id)a
    RepoCommunityFlag |> ORM.upsert_by(clauses, Map.merge(attrs, clauses))
  end

  @doc """
  set content to diffent community
  """
  def set_community(%Community{id: community_id}, thread, content_id) do
    with {:ok, action} <- match_action(thread, :community),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :communities),
         {:ok, community} <- ORM.find(action.reactor, community_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:communities, content.communities ++ [community])
      |> Repo.update()
    end
  end

  def unset_community(%Community{id: community_id}, thread, content_id) do
    with {:ok, action} <- match_action(thread, :community),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :communities),
         {:ok, community} <- ORM.find(action.reactor, community_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:communities, content.communities -- [community])
      |> Repo.update()
    end
  end

  @doc """
  set general tag for post / tuts ...
  """
  # check community first
  def set_tag(thread, %Tag{id: tag_id}, content_id) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      update_content_tag(content, tag)

      # NOTE: this should be control by Middleware
      # case tag_in_community_thread?(%Community{id: communitId}, thread, tag) do
      # true ->
      # content
      # |> Ecto.Changeset.change()
      # |> Ecto.Changeset.put_assoc(:tags, content.tags ++ [tag])
      # |> Repo.update()

      # _ ->
      # {:error, message: "Tag,Community,Thread not match", code: ecode(:custom)}
      # end
    end
  end

  def unset_tag(thread, %Tag{id: tag_id}, content_id) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      update_content_tag(content, tag, :drop)
    end
  end

  defp update_content_tag(content, %Tag{} = tag, opt \\ :add) do
    new_tags = if opt == :add, do: content.tags ++ [tag], else: content.tags -- [tag]

    content
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, new_tags)
    |> Repo.update()
  end

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

  @doc "lock comment of a article"
  # TODO: record it to ArticleLog
  def lock_article_comment(
        %{meta: %Embeds.ArticleMeta{is_comment_locked: false} = meta} = content
      ) do
    meta =
      meta
      |> Map.from_struct()
      |> Map.delete(:id)
      |> Map.merge(%{is_comment_locked: true})

    ORM.update_meta(content, meta)
  end

  def lock_article_comment(content), do: {:ok, content}

  # check if the thread has aready enough pined articles
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
