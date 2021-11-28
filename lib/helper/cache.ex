defmodule Helper.Cache do
  @moduledoc """
  memory cache using cachex https://github.com/whitfin/cachex
  """
  import Cachex.Spec
  import Helper.Utils, only: [get_config: 2]

  @cache_pool get_config(:cache, :pool)

  def config(pool_name) do
    [
      limit: limit(size: @cache_pool[pool_name].size, policy: Cachex.Policy.LRW, reclaim: 0.1),
      expiration: expiration(default: :timer.seconds(@cache_pool[pool_name].seconds))
    ]
  end

  # # size, minites
  # def config(:common) do
  #   [
  #     limit: limit(size: 5000, policy: Cachex.Policy.LRW, reclaim: 0.1),
  #     expiration: expiration(default: :timer.minutes(10))
  #   ]
  # end

  # @doc """
  # cache config for user.login -> user.id, used in accounts resolver
  # user.id is a linearly increasing integer, kind sensitive, so use user.login instead
  # """
  # def config(:user_login) do
  #   [
  #     limit: limit(size: 10_000, policy: Cachex.Policy.LRW, reclaim: 0.1),
  #     # expired in one week, it's fine, since user's login and id will never change
  #     expiration: expiration(default: :timer.minutes(10_080))
  #   ]
  # end

  # def config(:blog_rss) do
  #   [
  #     limit: limit(size: 1000, policy: Cachex.Policy.LRW, reclaim: 0.1),
  #     # expired in one week, it's fine, since user's login and id will never change
  #     expiration: expiration(default: :timer.minutes(10))
  #   ]
  # end

  @doc """
  ## Example
  iex> Helper.Cache.get(:common, :a)
  {:ok, "b"}
  """
  @spec get(Atom.t(), String.t()) :: {:error, nil} | {:ok, any}
  def get(pool, key) do
    case Cachex.get(pool, key) do
      {:ok, nil} -> {:error, nil}
      {:ok, result} -> {:ok, result}
    end
  end

  @doc """
  ## Example
  iex> Helper.Cache.put(a, "x")
  {:ok, "x"}
  """
  def put(pool, key, value) do
    Cachex.put(pool, key, value)
  end

  def put(pool, key, value, expire_sec: expire_sec) do
    Cachex.put(pool, key, value)
    Cachex.expire(pool, key, :timer.seconds(expire_sec))
  end

  def put(pool, key, value, expire_min: expire_min) do
    Cachex.put(pool, key, value)
    Cachex.expire(pool, key, :timer.minutes(expire_min))
  end

  @doc """
  clear all the cache
  ## Example
  iex> Helper.Cache.clear()
  {:ok, 1}
  """
  def clear(pool), do: Cachex.clear(pool)

  @doc """
  cache scope of community contributes digest
  """
  def get_scope(:community_contributes, id), do: "community.contributes.#{id}"
end
