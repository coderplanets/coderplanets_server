defmodule GroupherServer.CMS.Delegate.ArticleOperation do
  @moduledoc """
  set / unset operations for Article-like resource
  """
  import GroupherServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false

  import Helper.ErrorCode
  import ShortMaps
  import GroupherServer.CMS.Utils.Matcher2

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
    PinnedArticle,
    PinedPost,
    PinedJob,
    PinedRepo
  }

  alias GroupherServer.CMS.Repo, as: CMSRepo
  alias GroupherServer.Repo

  alias Ecto.Multi

  @max_pinned_article_count_per_thread Community.max_pinned_article_count_per_thread()

  @spec pin_article(T.article_thread(), Integer.t(), Integer.t()) :: {:ok, PinnedArticle.t()}
  def pin_article(thread, article_id, community_id) do
    with {:ok, info} <- match(thread),
         {:ok, community} <- ORM.find(Community, community_id),
         {:ok, _} <- check_pinned_article_count(community_id, thread) do
      Multi.new()
      |> Multi.run(:update_article_pinned_flag, fn _, _ ->
        # ORM.update(comment, %{is_pinned: true})
        {:ok, :pass}
      end)
      |> Multi.run(:create_pinned_article, fn _, _ ->
        thread_upcase = thread |> to_string |> String.upcase()

        args =
          Map.put(
            %{community_id: community.id, thread: thread_upcase},
            info.foreign_key,
            article_id
          )

        PinnedArticle |> ORM.create(args)
      end)
      |> Repo.transaction()
      |> create_pinned_article_result()
    end
  end

  def pin_content(%Post{id: post_id}, %Community{id: community_id}) do
    with {:ok, pined} <-
           ORM.findby_or_insert(
             PinedPost,
             ~m(post_id community_id)a,
             ~m(post_id community_id)a
           ) do
      Post |> ORM.find(pined.post_id)
    end
  end

  def pin_content(%Job{id: job_id}, %Community{id: community_id}) do
    attrs = ~m(job_id community_id)a

    with {:ok, pined} <- ORM.findby_or_insert(PinedJob, attrs, attrs) do
      Job |> ORM.find(pined.job_id)
    end
  end

  def pin_content(%CMSRepo{id: repo_id}, %Community{id: community_id}) do
    attrs = ~m(repo_id community_id)a

    with {:ok, pined} <- ORM.findby_or_insert(PinedRepo, attrs, attrs) do
      CMSRepo |> ORM.find(pined.repo_id)
    end
  end

  def undo_pin_content(%Post{id: post_id}, %Community{id: community_id}) do
    with {:ok, pined} <- ORM.find_by(PinedPost, ~m(post_id community_id)a),
         {:ok, deleted} <- ORM.delete(pined) do
      Post |> ORM.find(deleted.post_id)
    end
  end

  def undo_pin_content(%Job{id: job_id}, %Community{id: community_id}) do
    with {:ok, pined} <- ORM.find_by(PinedJob, ~m(job_id community_id)a),
         {:ok, deleted} <- ORM.delete(pined) do
      Job |> ORM.find(deleted.job_id)
    end
  end

  def undo_pin_content(%CMSRepo{id: repo_id}, %Community{id: community_id}) do
    with {:ok, pined} <- ORM.find_by(PinedRepo, ~m(repo_id community_id)a),
         {:ok, deleted} <- ORM.delete(pined) do
      CMSRepo |> ORM.find(deleted.repo_id)
    end
  end

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
  refined tag can't set by this func, use set_refined_tag instead
  """
  # check community first
  def set_tag(thread, %Tag{id: tag_id}, content_id) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      case tag.title != "refined" do
        true ->
          update_content_tag(content, tag)

        false ->
          {:error, "use set_refined_tag instead"}
      end

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

  @doc """
  set refined_tag to common content
  """
  def set_refined_tag(%Community{id: community_id}, thread, content_id) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :tags),
         {:ok, tag} <-
           ORM.find_by(action.reactor, %{
             title: "refined",
             community_id: community_id
           }) do
      update_content_tag(content, tag)
    end
  end

  @doc """
  unset refined_tag to common content
  """
  def unset_refined_tag(%Community{id: community_id}, thread, content_id) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :tags),
         {:ok, tag} <-
           ORM.find_by(action.reactor, %{
             title: "refined",
             community_id: community_id
           }) do
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
    new_meta =
      meta
      |> Map.from_struct()
      |> Map.delete(:id)
      |> Map.merge(%{is_edited: true})

    do_update_meta(content, new_meta)
  end

  # for test or exsiting articles
  def update_edit_status(%{meta: nil} = content) do
    new_meta = Embeds.ArticleMeta.default_meta() |> Map.merge(%{is_edited: true})

    do_update_meta(content, new_meta)
  end

  def update_edit_status(content, _), do: {:ok, content}

  @doc "lock comment of a article"
  # TODO: record it to ArticleLog
  def lock_article_comment(
        %{meta: %Embeds.ArticleMeta{is_comment_locked: false} = meta} = content
      ) do
    new_meta =
      meta
      |> Map.from_struct()
      |> Map.delete(:id)
      |> Map.merge(%{is_comment_locked: true})

    do_update_meta(content, new_meta)
  end

  def lock_article_comment(content), do: {:ok, content}

  # TODO: put it into ORM helper
  defp do_update_meta(%{meta: _} = content, meta_params) do
    content
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:meta, meta_params)
    |> Repo.update()
  end

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

  defp create_pinned_article_result({:ok, %{create_pinned_article: result}}), do: {:ok, result}

  defp create_pinned_article_result({:error, _, result, _steps}) do
    {:error, result}
  end
end
