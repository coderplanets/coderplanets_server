defmodule GroupherServer.Accounts.Delegate.Utils do
  @moduledoc """
  utils for Accounts
  """
  alias GroupherServer.Accounts
  alias Accounts.Model.User
  alias Helper.{Cache, ORM}

  @cache_pool :user_login

  @doc """
  get and cache user'id by user's login
  """
  @spec get_userid_and_cache(String.t()) :: {:ok, Integer.t()} | {:error, any}
  def get_userid_and_cache(login) do
    case Cache.get(@cache_pool, login) do
      {:ok, user_id} -> {:ok, user_id}
      {:error, _} -> get_and_cache(login)
    end
  end

  defp get_and_cache(login) do
    with {:ok, user} <- ORM.find_by(User, %{login: login}) do
      Cache.put(@cache_pool, login, user.id)
      {:ok, user.id}
    end
  end
end
