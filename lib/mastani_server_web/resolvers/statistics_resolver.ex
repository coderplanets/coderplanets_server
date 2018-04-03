defmodule MastaniServerWeb.Resolvers.Statistics do
  alias MastaniServer.Statistics
  alias MastaniServer.Accounts.User
  # alias Helper.ORM

  def user_contributes(_root, %{user_id: user_id}, _info) do
    # Statistics.list_user_contributes(String.to_integer(user_id)) |> IO.inspect
    Statistics.list_user_contributes(%User{id: user_id})
  end

  def make_contrubute(_root, %{user_id: user_id}, _info) do
    Statistics.make_contribute(%User{id: user_id})
  end
end
