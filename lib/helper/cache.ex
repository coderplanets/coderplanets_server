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

  def put(cache_key, cache_value, expire: expire_time) do
    Cachex.put(:site_cache, cache_key, cache_value)
    Cachex.expire(:site_cache, cache_key, expire_time)
  end

  @doc """
  clear all the cache
  ## Example
  iex> Helper.Cache.clear()
  {:ok, 1}
  """
  def clear_all(), do: Cachex.clear(:site_cache)

  @doc """
  cache scope of community contributes digest
  """
  def get_scope(:community_contributes, id), do: "community.contributes.#{id}"
end
