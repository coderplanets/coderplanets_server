defmodule GroupherServerWeb.Resolvers.Statistics do
  @moduledoc """
  resolvers for Statistics
  """
  alias GroupherServer.{Accounts, CMS, Statistics}
  alias CMS.Model.Community
  alias Accounts.Model.User

  # tmp for test

  def list_contributes_digest(%Community{id: id}, _args, _info) do
    Statistics.list_contributes_digest(%Community{id: id})
  end

  def make_contrubute(_root, %{user_id: user_id}, _info) do
    Statistics.make_contribute(%User{id: user_id})
  end

  def list_cities_geo_info(_root, _args, _info) do
    Statistics.list_cities_info()
  end

  def online_status(_root, _args, _info) do
    Statistics.online_status()
  end

  def count_status(_root, _args, _info) do
    Statistics.count_status()
  end
end
