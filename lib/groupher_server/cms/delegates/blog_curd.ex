defmodule GroupherServer.CMS.Delegate.BlogCURD do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false

  # import Helper.Utils, only: [done: 1]

  # import Helper.ErrorCode
  # import ShortMaps

  # alias Helper.{ORM}
  alias GroupherServer.{CMS, Repo}
  alias CMS.Model.BlogRSS

  alias Helper.{Cache, RSS}

  @cache_pool :blog_rss

  # alias Ecto.Multi
  def blog_rss_feed(rss) when is_binary(rss) do
    get_feed_and_cache(rss)
  end

  @doc """
  get and cache user'id by user's login
  """
  def get_feed_and_cache(rss) do
    case Cache.get(@cache_pool, rss) do
      {:ok, feed} -> {:ok, feed}
      {:error, _} -> do_get_feed_and_cache(rss)
    end
  end

  defp do_get_feed_and_cache(rss) do
    # {:ok, feed} = RSS.get(rss)
    with {:ok, feed} = RSS.get(rss) do
      Cache.put(@cache_pool, rss, feed)
      {:ok, feed}
    end
  end

  def create_blog() do
    # 1. 先判断 rss 是否存在
    ##  1.1 如果存在，从 cache 中获取
    ##  1.2 如不存在，则创建一条 RSS

    # 2. 创建 blog
    ##  2.1 blog +字段 rss, author
    ##  2.2 title, digest, xxx

    # 前台获取作者信息的时候从 rss 表读取
  end

  def create_blog_rss(attrs) do
    history_feed = Map.get(attrs, :history_feed)
    attrs = attrs |> Map.drop([:history_feed])

    %BlogRSS{}
    |> Ecto.Changeset.change(attrs)
    |> Ecto.Changeset.put_embed(:history_feed, history_feed)
    |> Repo.insert()
  end

  # create done
  # defp result({:ok, %{set_active_at_timestamp: result}}) do
  #   {:ok, result}
  # end

  # defp result({:ok, %{update_article_meta: result}}), do: {:ok, result}

  # defp result({:error, :create_article, _result, _steps}) do
  #   {:error, [message: "create article", code: ecode(:create_fails)]}
  # end

  # defp result({:error, _, result, _steps}), do: {:error, result}
end
