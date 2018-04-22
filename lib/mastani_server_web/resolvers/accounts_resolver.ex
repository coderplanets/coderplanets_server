defmodule MastaniServerWeb.Resolvers.Accounts do
  # import ShortMaps

  alias MastaniServer.Accounts
  alias Helper.ORM

  def user(_root, %{id: id}, _info), do: Accounts.User |> ORM.find(id)

  def account(_root, _args, %{context: %{cur_user: cur_user}}),
    do: Accounts.User |> ORM.find(cur_user.id)

  def github_signin(_root, %{github_user: github_user}, _info) do
    Accounts.github_signin(github_user)
  end

  def subscribed_communities(_root, %{user_id: "", filter: filter}, _info) do
    Accounts.default_subscribed_communities(filter)
  end

  def subscribed_communities(_root, %{user_id: user_id, filter: filter}, _info) do
    Accounts.subscribed_communities(%Accounts.User{id: user_id}, filter)
  end

  def subscribed_communities(_root, %{filter: filter}, _info) do
    Accounts.default_subscribed_communities(filter)
  end

  # def create_user(_root, args, %{context: %{cur_user: %{root: true}}}) do
  # Accounts.create_user2(args)
  # end
end
