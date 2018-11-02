defmodule MastaniServer.CMS.Delegate.ArticleOperation do
  @moduledoc """
  set / unset operations for Article-like resource
  """
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false
  # import Helper.ErrorCode
  import ShortMaps

  alias Helper.ORM

  alias MastaniServer.CMS.{
    Community,
    Post,
    PostCommunityFlag,
    Job,
    JobCommunityFlag,
    RepoCommunityFlag,
    Video,
    VideoCommunityFlag,
    Tag,
    Topic,
    PinedPost,
    PinedJob,
    PinedVideo,
    PinedRepo
  }

  alias MastaniServer.CMS.Repo, as: CMSRepo
  alias MastaniServer.Repo

  def pin_content(%Post{id: post_id}, %Community{id: community_id}, topic) do
    with {:ok, %{id: topic_id}} <- ORM.find_by(Topic, %{raw: topic}),
         {:ok, pined} <-
           ORM.findby_or_insert(
             PinedPost,
             ~m(post_id community_id topic_id)a,
             ~m(post_id community_id topic_id)a
           ) do
      Post |> ORM.find(pined.post_id)
    end
  end

  def undo_pin_content(%Post{id: post_id}, %Community{id: community_id}, topic) do
    with {:ok, %{id: topic_id}} <- ORM.find_by(Topic, %{raw: topic}),
         {:ok, pined} <- ORM.find_by(PinedPost, ~m(post_id community_id topic_id)a),
         {:ok, deleted} <- ORM.delete(pined) do
      Post |> ORM.find(deleted.post_id)
    end
  end

  def pin_content(%Job{id: job_id}, %Community{id: community_id}) do
    attrs = ~m(job_id community_id)a

    with {:ok, pined} <- ORM.findby_or_insert(PinedJob, attrs, attrs) do
      Job |> ORM.find(pined.job_id)
    end
  end

  def undo_pin_content(%Job{id: job_id}, %Community{id: community_id}) do
    with {:ok, pined} <- ORM.find_by(PinedJob, ~m(job_id community_id)a),
         {:ok, deleted} <- ORM.delete(pined) do
      Job |> ORM.find(deleted.job_id)
    end
  end

  def pin_content(%Video{id: video_id}, %Community{id: community_id}) do
    attrs = ~m(video_id community_id)a

    with {:ok, pined} <- ORM.findby_or_insert(PinedVideo, attrs, attrs) do
      Video |> ORM.find(pined.video_id)
    end
  end

  def undo_pin_content(%Video{id: video_id}, %Community{id: community_id}) do
    with {:ok, pined} <- ORM.find_by(PinedVideo, ~m(video_id community_id)a),
         {:ok, deleted} <- ORM.delete(pined) do
      Video |> ORM.find(deleted.video_id)
    end
  end

  def pin_content(%CMSRepo{id: repo_id}, %Community{id: community_id}) do
    attrs = ~m(repo_id community_id)a

    with {:ok, pined} <- ORM.findby_or_insert(PinedRepo, attrs, attrs) do
      CMSRepo |> ORM.find(pined.repo_id)
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
  def set_community_flags(%Post{id: _} = content, community_id, attrs),
    do: do_set_flag(content, community_id, attrs)

  def set_community_flags(%Job{id: _} = content, community_id, attrs),
    do: do_set_flag(content, community_id, attrs)

  def set_community_flags(%CMSRepo{id: _} = content, community_id, attrs),
    do: do_set_flag(content, community_id, attrs)

  def set_community_flags(%Video{id: _} = content, community_id, attrs),
    do: do_set_flag(content, community_id, attrs)

  defp do_set_flag(content, community_id, attrs) do
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

  defp insert_flag_record(%Video{id: video_id}, community_id, attrs) do
    clauses = ~m(video_id community_id)a
    VideoCommunityFlag |> ORM.upsert_by(clauses, Map.merge(attrs, clauses))
  end

  @doc """
  set content to diffent community
  """
  def set_community(%Community{id: community_id}, thread, content_id) when valid_thread(thread) do
    with {:ok, action} <- match_action(thread, :community),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :communities),
         {:ok, community} <- ORM.find(action.reactor, community_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:communities, content.communities ++ [community])
      |> Repo.update()
    end
  end

  def unset_community(%Community{id: community_id}, thread, content_id)
      when valid_thread(thread) do
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
  set tag for post / tuts / videos ...
  """
  # check community first
  def set_tag(%Community{id: _communitId}, thread, %Tag{id: tag_id}, content_id) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, content.tags ++ [tag])
      |> Repo.update()

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

  def unset_tag(thread, %Tag{id: tag_id}, content_id) when valid_thread(thread) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, content.tags -- [tag])
      |> Repo.update()
    end
  end

  @doc """
  set topic only for post
  """
  def set_topic(%Topic{title: title}, :post, content_id) do
    with {:ok, content} <- ORM.find(Post, content_id, preload: :topics),
         {:ok, topic} <-
           ORM.findby_or_insert(Topic, %{title: title}, %{
             title: title,
             thread: "post",
             raw: title
           }) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:topics, content.topics ++ [topic])
      |> Repo.update()
    end
  end

  def set_topic(_topic, _thread, _content_id), do: {:ok, :pass}

  # make sure the reuest tag is in the current community thread
  # example: you can't set a other thread tag to this thread's article
  defp tag_in_community_thread?(%Community{id: communityId}, thread, tag) do
    with {:ok, community} <- ORM.find(Community, communityId) do
      matched_tags =
        Tag
        |> where([t], t.community_id == ^community.id)
        # |> where([t], t.thread == ^(to_string(thread) |> String.upcase()))
        |> where([t], t.thread == ^to_string(thread))
        |> Repo.all()

      tag in matched_tags
    end
  end
end
