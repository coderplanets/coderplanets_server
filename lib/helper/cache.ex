defmodule Helper.Cache do
  @moduledoc """
  memory cache using cachex https://github.com/whitfin/cachex
  """

  @doc """
  ## Example
  iex> Helper.Cache.get(a)
  {:ok, "b"}
  """
  def get(cache_key) do
    case Cachex.get(:site_cache, cache_key) do
      {:ok, nil} ->
        {:error, nil}

      {:ok, result} ->
        {:ok, result}
    end
  end

  @doc """
  ## Example
  iex> Helper.Cache.put(a, "x")
  {:ok, "x"}
  """
  def put(cache_key, cache_value) do
    Cachex.put(:site_cache, cache_key, cache_value)
  end

  @doc """
  cache scope of community contributes digest
  """
  def get_scope(:community_contributes, id), do: "community.contributes.#{id}"
end
