defmodule MastaniServer.CMS.Delegate.ArticleOperation do
  @moduledoc """
  set / unset operations for Article-like resource
  """
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.ORM
  alias MastaniServer.Accounts.User

  alias MastaniServer.CMS.{
    Community,
    PinState,
    Post,
    PostCommunityFlag,
    Job,
    JobCommunityFlag,
    RepoCommunityFlag,
    Video,
    VideoCommunityFlag,
    Tag
  }

  alias MastaniServer.CMS.Repo, as: CMSRepo
  alias MastaniServer.Repo

  @doc """
  pin / unpin, trash / untrash articles
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
         {:ok, record} <- insert_flag_record(content, community_id, attrs) do
      {:ok, struct(content, %{pin: record.pin, trash: record.trash})}
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
  def set_tag(%Community{id: communitId}, thread, %Tag{id: tag_id}, content_id) do
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
