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
    Cachex.get(:site_cache, cache_key)
  end

  @doc """
  ## Example
  iex> Helper.Cache.put(a, "x")
  {:ok, "x"}
  """
  def put(cache_key, cache_value) do
    Cachex.put(:site_cache, cache_key, cache_value)
  end
end
