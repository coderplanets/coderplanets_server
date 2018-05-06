defmodule MastaniServer.CMS.Delegate.CommunityOperation do
  import ShortMaps

  alias MastaniServer.{Repo, Accounts}
  alias Helper.ORM

  alias MastaniServer.CMS.{
    # Author,
    # Thread,
    # CommunityThread,
    # Tag,
    Community,
    CommunitySubscriber
    # CommunityEditor
  }

  @doc """
  subscribe a community. (ONLY community, post etc use watch )
  """
  def subscribe_community(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, record} <- CommunitySubscriber |> ORM.create(~m(user_id community_id)a) do
      Community |> ORM.find(record.community_id)
    end
  end

  def unsubscribe_community(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, record} <-
           CommunitySubscriber |> ORM.findby_delete(community_id: community_id, user_id: user_id) do
      Community |> ORM.find(record.community_id)
    end
  end
end
