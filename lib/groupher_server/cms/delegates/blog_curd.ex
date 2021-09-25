defmodule GroupherServer.CMS.Delegate.BlogCURD do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [strip_struct: 1]

  import GroupherServer.CMS.Delegate.ArticleCURD, only: [create_article: 4]
  # import Helper.Utils, only: [done: 1]

  # import Helper.ErrorCode
  # import ShortMaps

  # alias Helper.{ORM}
  alias GroupherServer.{Accounts, CMS, Repo}
  alias CMS.Model.{BlogRSS, Community}
  alias Accounts.Model.User

  alias Helper.{ORM, Cache, RSS}

  @cache_pool :blog_rss

  # alias Ecto.Multi
  def blog_rss_feed(rss) when is_binary(rss) do
    with {:ok, feed} <- ORM.find_by(BlogRSS, %{rss: rss}) do
      {:ok, feed}
    else
      _ -> fetch_fresh_feed_and_cache(rss)
    end
  end

  # attrs 包含 rss, blog_title
  # def create_article(%Community{id: cid}, thread, attrs, %User{id: uid}) do
  def create_blog(%Community{} = community, attrs, %User{} = user) do
    # 1. 先判断 rss 是否存在
    ##  1.1 如果存在，从 cache 中获取
    ##  1.2 如不存在，则创建一条 RSS
    with {:ok, feed} <- blog_rss_feed(attrs.rss) do
      do_create_blog(community, attrs, user, feed)

      # IO.inspect(feed, label: "create blog")
      # 通过 feed 有没有 id 来 insert / update
      # 通过 blog_title, 组合 attrs 传给 create_article
    end

    # 2. 创建 blog
    ##  2.1 blog +字段 rss, author
    ##  2.2 title, digest, xxx

    # 前台获取作者信息的时候从 rss 表读取
  end

  defp do_create_blog(%Community{} = community, attrs, %User{} = user, %{id: _} = feed) do
    IO.inspect("rss 记录存在, 直接创建 blog", label: "do_create_blog")

    # author = feed.author
    selected_feed = Enum.find(feed.history_feed, &(&1.title == attrs.title))
    IO.inspect(selected_feed, label: "target feed")
    IO.inspect(feed, label: "the author")
    # IO.inspect(feed, label: "feed -")

    attrs =
      attrs
      |> Map.merge(%{link_addr: selected_feed.link_addr, published: selected_feed.published})

    IO.inspect(attrs, label: "attrs -")
    create_article(community, :blog, attrs, user)
    # arg(:title, non_null(:string))
    # arg(:body, non_null(:string))
    # arg(:community_id, non_null(:id))
    # arg(:link_addr, :string)
  end

  defp do_create_blog(%Community{id: cid}, attrs, %User{id: uid}, feed) do
    IO.inspect("rss 记录不存在, 先创建 rss, 再创建 blog", label: "do_create_blog")
    {:ok, :pass}
  end

  def create_blog_rss(attrs) do
    history_feed = Map.get(attrs, :history_feed)
    attrs = attrs |> Map.drop([:history_feed])

    %BlogRSS{}
    |> Ecto.Changeset.change(attrs)
    |> Ecto.Changeset.put_embed(:history_feed, history_feed)
    |> Repo.insert()
  end

  def update_blog_rss(%{rss: rss} = attrs) do
    with {:ok, blog_rss} <- ORM.find_by(BlogRSS, rss: rss) do
      history_feed =
        Map.get(attrs, :history_feed, Enum.map(blog_rss.history_feed, &strip_struct(&1)))

      attrs = attrs |> Map.drop([:history_feed])

      %BlogRSS{}
      |> Ecto.Changeset.change(attrs)
      |> Ecto.Changeset.put_embed(:history_feed, history_feed)
      |> Repo.insert()
    end
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

  @doc """
  get and cache feed by rss address as key
  """
  def fetch_fresh_feed_and_cache(rss) do
    case Cache.get(@cache_pool, rss) do
      {:ok, feed} -> {:ok, feed}
      {:error, _} -> get_feed_and_cache(rss)
    end
  end

  defp get_feed_and_cache(rss) do
    # {:ok, feed} = RSS.get(rss)
    with {:ok, feed} = RSS.get(rss) do
      Cache.put(@cache_pool, rss, feed)
      {:ok, feed}
    end
  end
end
