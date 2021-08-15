defmodule Helper.Scheduler do
  @moduledoc """
  cron-like job scheduler
  """
  use Quantum.Scheduler, otp_app: :groupher_server
  # alias Helper.Cache

  @doc """
  clear all the cache in Cachex
  just in case the cache system broken
  """
  def clear_all_cache do
    # Cache.clear_all()
  end

  @doc """
  archive articles and comments based on config
  """
  def archive_artiments() do
    # TODO
  end
end
