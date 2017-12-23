defmodule MastaniServerWeb.Resolvers.Accounts do
  alias MastaniServer.Accounts

  def all_users(_root, _args, _info) do
    users = Accounts.list_users()
    {:ok, users}
  end

  def create_user(_root, args, _info) do
    case Accounts.create_user(args) do
      {:ok, link} ->
        {:ok, link}

      _error ->
        {:error, "could not create user"}
    end
  end
end
