defmodule MastaniServerWeb.Resolvers.Statistics do
  alias MastaniServer.{Accounts, CMS, Statistics}
  # alias Helper.ORM

  # tmp for test
  def list_contributes(_root, %{id: id}, _info) do
    Statistics.list_contributes(%Accounts.User{id: id})
  end

  def list_contributes(%Accounts.User{id: id}, _args, _info) do
    Statistics.list_contributes(%Accounts.User{id: id})
  end

  def list_contributes(%CMS.Community{id: id}, _args, _info) do
    Statistics.list_contributes(%CMS.Community{id: id})
  end

  def make_contrubute(_root, %{user_id: user_id}, _info) do
    Statistics.make_contribute(%Accounts.User{id: user_id})
  end
end
