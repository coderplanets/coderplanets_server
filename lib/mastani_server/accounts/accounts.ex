defmodule MastaniServer.Accounts do
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, get_config: 2]

  alias MastaniServer.CMS
  alias MastaniServer.Accounts.{User}
  alias Helper.{ORM, QueryBuilder}

  alias MastaniServer.Accounts.Delegate.AccountCURD

  @default_subscribed_communities get_config(:general, :default_subscribed_communities)

  defdelegate update_profile(user_id, attrs), to: AccountCURD

  defdelegate github_signin(github_user), to: AccountCURD

  def default_subscribed_communities(%{page: _, size: _} = filter) do
    filter = Map.merge(filter, %{size: @default_subscribed_communities})
    CMS.Community |> ORM.find_all(filter)
  end

  def subscribed_communities(%User{id: id}, %{page: page, size: size} = filter) do
    IO.inspect("the fuck ...")

    CMS.CommunitySubscriber
    |> where([c], c.user_id == ^id)
    |> join(:inner, [c], cc in assoc(c, :community))
    |> select([c, cc], cc)
    |> QueryBuilder.filter_pack(filter)
    |> ORM.paginater(page: page, size: size)
    |> done()
  end
end
