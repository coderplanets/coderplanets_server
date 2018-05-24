defmodule MastaniServer.CMS.Delegate.ArticleOperation do
  import MastaniServer.CMS.Utils.Matcher
  import Ecto.Query, warn: false

  alias MastaniServer.CMS.{Tag, Community}
  alias MastaniServer.Repo
  alias Helper.ORM

  def set_community(part, part_id, %Community{id: community_id}) when valid_part(part) do
    with {:ok, action} <- match_action(part, :community),
         {:ok, content} <- ORM.find(action.target, part_id, preload: :communities),
         {:ok, community} <- ORM.find(action.reactor, community_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:communities, content.communities ++ [community])
      |> Repo.update()
    end
  end

  # TODO: use community_id instead of title
  def unset_community(part, part_id, %Community{id: community_id}) when valid_part(part) do
    with {:ok, action} <- match_action(part, :community),
         {:ok, content} <- ORM.find(action.target, part_id, preload: :communities),
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
  def set_tag(part, part_id, %Community{id: communitId}, %Tag{id: tag_id}) do
    with {:ok, action} <- match_action(part, :tag),
         {:ok, content} <- ORM.find(action.target, part_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      case tag_in_community_part?(%Community{id: communitId}, part, tag) do
        true ->
          content
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:tags, content.tags ++ [tag])
          |> Repo.update()

        _ ->
          {:error, "Tag,Community,Part not match"}
      end
    end
  end

  def unset_tag(part, part_id, %Tag{id: tag_id}) when valid_part(part) do
    with {:ok, action} <- match_action(part, :tag),
         {:ok, content} <- ORM.find(action.target, part_id, preload: :tags),
         {:ok, tag} <- ORM.find(action.reactor, tag_id) do
      content
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, content.tags -- [tag])
      |> Repo.update()
    end
  end

  # make sure the reuest tag is in the current community part
  # example: you can't set a other part tag to this part's article
  defp tag_in_community_part?(%Community{id: communityId}, part, tag) do
    with {:ok, community} <- ORM.find(Community, communityId) do
      matched_tags =
        Tag
        |> where([t], t.community_id == ^community.id)
        |> where([t], t.part == ^(to_string(part) |> String.upcase()))
        |> Repo.all()

      tag in matched_tags
    end
  end
end
