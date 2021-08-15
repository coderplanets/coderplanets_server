defmodule Helper.Scheduler do
  @moduledoc """
  cron-like job scheduler
  """
  use Quantum.Scheduler, otp_app: :groupher_server

  import Helper.Utils, only: [get_config: 2]
  alias GroupherServer.CMS

  @article_threads get_config(:article, :threads)

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
    Enum.map(@article_threads, &CMS.archive_articles(&1))
  end

  def arthive_comments() do
    CMS.archive_comments()
  end
end
