defmodule GroupherServer.CMS.Delegate.BlogCURD do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [strip_struct: 1, done: 1]
  import GroupherServer.Support.Factory, only: [mock_rich_text: 1]
  import Helper.ErrorCode

  import GroupherServer.CMS.Delegate.ArticleCURD, only: [create_article: 4]

  alias GroupherServer.{Accounts, CMS, Repo}
  alias CMS.Model.{BlogRSS, Community}
  alias Accounts.Model.User

  alias Helper.{ORM, Cache, RSS}

  @cache_pool :blog_rss

  # alias Ecto.Multi
  def blog_rss_info(rss) when is_binary(rss) do
    with {:ok, feed} <- ORM.find_by(BlogRSS, %{rss: rss}) do
      {:ok, feed}
    else
      _ ->
        fetch_fresh_rssinfo_and_cache(rss)
    end
  end

  # attrs 包含 rss, blog_title
  # def create_article(%Community{id: cid}, thread, attrs, %User{id: uid}) do
  def create_blog(%Community{} = community, attrs, %User{} = user) do
    # 1. 先判断 rss 是否存在
    ##  1.1 如果存在，从 cache 中获取
    ##  1.2 如不存在，则创建一条 RSS
    with {:ok, feed} <- blog_rss_info(attrs.rss) do
      do_create_blog(community, attrs, user, feed)
    end
  end

  def update_rss_author(rss, attrs) do
    with {:ok, feed} <- ORM.find_by(BlogRSS, %{rss: rss}) do
      ORM.update_embed(feed, :author, Map.drop(attrs, [:rss]))
    end
  end

  # rss 记录存在, 直接创建 blog
  defp do_create_blog(%Community{} = community, attrs, %User{} = user, %{id: _} = feed) do
    blog_author = if is_nil(feed.author), do: nil, else: Map.from_struct(feed.author)
    selected_feed = Enum.find(feed.history_feed, &(&1.title == attrs.title))

    with {:ok, attrs} <- build_blog_attrs(attrs, blog_author, selected_feed) do
      # TODO: feed_digest, feed_content
      create_article(community, :blog, attrs, user)
    end
  end

  # rss 记录不存在, 先创建 rss, 再创建 blog
  defp do_create_blog(%Community{} = community, attrs, %User{} = user, _feed) do
    with {:ok, feed} <- CMS.blog_rss_info(attrs.rss),
         {:ok, feed} <- create_blog_rss(feed) do
      do_create_blog(community, attrs, user, feed)
    end
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

  @doc """
  get and cache feed by rss address as key
  """
  def fetch_fresh_rssinfo_and_cache(rss) do
    case Cache.get(@cache_pool, rss) do
      {:ok, rssinfo} -> {:ok, rssinfo}
      {:error, _} -> get_rssinfo_and_cache(rss)
    end
  end

  defp get_rssinfo_and_cache(rss) do
    IO.inspect(rss, label: "the rss")

    with {:ok, rssinfo} <- RSS.query(rss) do
      Cache.put(@cache_pool, rss, rssinfo)
      {:ok, rssinfo}
    else
      {:error, _} -> {:error, [message: "blog rss is invalid", code: ecode(:invalid_blog_rss)]}
    end
  end

  defp build_blog_attrs(_attrs, _blog_author, nil),
    do: {:error, [message: "blog title not in rss", code: ecode(:invalid_blog_title)]}

  defp build_blog_attrs(attrs, blog_author, selected_feed) do
    attrs
    |> Map.merge(%{
      rss: attrs.rss,
      link_addr: selected_feed.link_addr,
      published: selected_feed.published,
      blog_author: blog_author,
      body: mock_rich_text("pleace use content field instead")
    })
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> done
  end
end
