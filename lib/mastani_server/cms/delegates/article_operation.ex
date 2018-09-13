defmodule MastaniServer.CMS.Delegate.ArticleOperation do
  @moduledoc """
  set / unset operations for Article-like resource
  """
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false
  import Helper.ErrorCode
  # import ShortMaps

  alias Helper.ORM
  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS.{Community, PinState, Post, PostCommunityFlags, Tag}
  alias MastaniServer.Repo

  @doc """
  pin / unpin, trash / untrash articles
  """
  def set_community_flags(%Post{id: post_id}, community_id, attrs) do
    with {:ok, post} <- ORM.find(Post, post_id),
         {:ok, community} <- ORM.find(Community, community_id),
         {:ok, _} <- insert_flag_record(post, community_id, attrs) do
      ORM.find(Post, post.id)
    end
  end

  defp insert_flag_record(%Post{id: id}, community_id, attrs) do
    clauses = %{
      post_id: id,
      community_id: community_id
    }

    attrs = attrs |> Map.merge(clauses)

    PostCommunityFlags |> ORM.upsert_by(clauses, attrs)
  end

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
