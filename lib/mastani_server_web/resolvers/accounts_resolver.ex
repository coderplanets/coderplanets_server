defmodule MastaniServerWeb.Resolvers.Accounts do
  import ShortMaps

  alias MastaniServer.Accounts
  alias MastaniServer.CMS
  alias Helper.ORM

  def user(_root, %{id: id}, _info), do: Accounts.User |> ORM.find(id)
  def users(_root, ~m(filter)a, _info), do: Accounts.User |> ORM.find_all(filter)

  def account(_root, _args, %{context: %{cur_user: cur_user}}),
    do: Accounts.User |> ORM.find(cur_user.id)

  def update_profile(_root, %{profile: profile}, %{context: %{cur_user: cur_user}}) do
    Accounts.update_profile(%Accounts.User{id: cur_user.id}, profile)
  end

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

  def get_passport(_root, _args, %{context: %{cur_user: cur_user}}) do
    CMS.get_passport(%Accounts.User{id: cur_user.id})
  end

  # def create_user(_root, args, %{context: %{cur_user: %{root: true}}}) do
  # Accounts.create_user2(args)
  # end
end
