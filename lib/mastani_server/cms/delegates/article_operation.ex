defmodule MastaniServer.CMS.Delegate.ArticleOperation do
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false
  import Helper.ErrorCode

  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS.{Tag, Community}
  alias MastaniServer.Repo
  alias Helper.ORM

  @doc """
  pin / unpin, trash / untrash articles
  """
  def set_flag(queryable, id, %{pin: _} = attrs, %User{} = _user) do
    queryable |> ORM.find_update(id, attrs)
  end

  def set_flag(queryable, id, %{trash: _} = attrs, %User{} = _user) do
    queryable |> ORM.find_update(id, attrs)
  end

  def set_community(thread, content_id, %Community{id: community_id}) when valid_thread(thread) do
    with {:ok, action} <- match_action(thread, :community),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :communities),
         {:ok, community} <- ORM.find(action.reactor, community_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:communities, content.communities ++ [community])
      |> Repo.update()
    end
  end

  # TODO: use community_id instead of title
  def unset_community(thread, content_id, %Community{id: community_id})
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
  def set_tag(thread, content_id, %Community{id: communitId}, %Tag{id: tag_id}) do
    with {:ok, action} <- match_action(thread, :tag),
         {:ok, content} <- ORM.find(action.target, content_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      case tag_in_community_thread?(%Community{id: communitId}, thread, tag) do
        true ->
          content
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:tags, content.tags ++ [tag])
          |> Repo.update()

        _ ->
          {:error, message: "Tag,Community,Thread not match", code: ecode(:custom)}
      end
    end
  end

  def unset_tag(thread, content_id, %Tag{id: tag_id}) when valid_thread(thread) do
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
