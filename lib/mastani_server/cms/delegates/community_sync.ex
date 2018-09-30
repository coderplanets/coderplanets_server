defmodule MastaniServer.CMS.Delegate.CommunitySync do
  @moduledoc """
  community curd
  """
  import Ecto.Query, warn: false
  import Helper.ErrorCode
  import ShortMaps

  alias Helper.ORM

  alias MastaniServer.CMS.{
    Community,
    CommunityWiki
  }

  @doc """
  get wiki
  """
  def get_wiki(%Community{raw: raw}) do
    with {:ok, community} <- ORM.find_by(Community, raw: raw),
         {:ok, wiki} <- ORM.find_by(CommunityWiki, community_id: community.id) do
      CommunityWiki |> ORM.read(wiki.id, inc: :views)
    end
  end

  @doc """
  return paged community subscribers
  """
  def sync_content(%Community{id: id}, :wiki, attrs) do
    with {:ok, community} <- ORM.find(Community, id) do
      attrs = Map.merge(attrs, %{community_id: community.id})

      CommunityWiki |> ORM.upsert_by([community_id: community.id], attrs)
    end
  end

  @doc """
  add contributor to exsit wiki contributors list
  """
  def add_contributor(%CommunityWiki{id: id}, contributor_attrs) do
    do_add_contributor(CommunityWiki, id, contributor_attrs)
  end

  defp do_add_contributor(queryable, id, contributor_attrs) do
    with {:ok, content} <- ORM.find(queryable, id) do
      cur_contributors =
        Enum.reduce(content.contributors, [], fn user, acc ->
          acc ++ [Map.from_struct(user)]
        end)

      case cur_contributors |> Enum.any?(&(&1.github_id == contributor_attrs.github_id)) do
        true ->
          {:error, [message: "already added", code: ecode(:already_exsit)]}

        false ->
          new_contributors = %{contributors: cur_contributors ++ [contributor_attrs]}
          content |> ORM.update(new_contributors)
      end
    end
  end
end
