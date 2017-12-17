defmodule MastaniServerWeb.Resolvers.Accounts do
  alias MastaniServer.Accounts

  def all_users(_root, _args, _info) do
    users = Accounts.list_users()
    {:ok, users}
  end
end
