defmodule MastaniServerWeb.Resolvers.Accounts do
  alias MastaniServer.Accounts
  alias Helper.ORM

  def user(_root, %{id: id}, _info), do: Accounts.User |> ORM.find(id)

  def github_signin(_root, %{github_user: github_user}, _info) do
    Accounts.github_signin(github_user)
  end

  def subscried_communities(_root, %{filter: filter}, %{context: %{cur_user: cur_user}}) do
    Accounts.subscried_communities(%Accounts.User{id: cur_user.id}, filter)
  end

  # def create_user(_root, args, %{context: %{cur_user: %{root: true}}}) do
  # Accounts.create_user2(args)
  # end
end
