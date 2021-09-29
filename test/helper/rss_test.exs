defmodule GroupherServer.Test.Helper.RSSTest do
  @moduledoc false
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias Helper.{Cache}

  @cache_pool :blog_rss
  @rss mock_rss_addr()

  setup do
    {:ok, community} = db_insert(:community)
    {:ok, user} = db_insert(:user)

    {:ok, ~m(community user)a}
  end

  describe "blog curd" do
    @tag :wip2
    test "can create blog", ~m(community user)a do
      {:ok, feed} = CMS.blog_rss_info(@rss)
      {:ok, _rss_record} = CMS.create_blog_rss(feed)

      selected_feed = feed.history_feed |> List.first()
      title = selected_feed |> Map.get(:title)
      link_addr = selected_feed |> Map.get(:link_addr)
      # blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      blog_attrs = %{
        rss: @rss,
        title: title,
        body: mock_rich_text("pleace use content field instead")
      }

      {:ok, blog} = CMS.create_blog(community, blog_attrs, user)
      assert blog.title == title
      assert blog.link_addr == link_addr
    end

    @tag :wip2
    test "can create blog with no-exsit rss record", ~m(community user)a do
      {:ok, feed} = CMS.blog_rss_info(@rss)

      selected_feed = feed.history_feed |> List.first()
      title = selected_feed |> Map.get(:title)
      link_addr = selected_feed |> Map.get(:link_addr)
      # blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      blog_attrs = %{
        rss: @rss,
        title: title,
        body: mock_rich_text("pleace use content field instead")
      }

      {:ok, blog} = CMS.create_blog(community, blog_attrs, user)
      assert blog.title == title
      assert blog.link_addr == link_addr
    end

    @tag :wip2
    test "can create blog with blog_author", ~m(community user)a do
      {:ok, feed} = CMS.blog_rss_info(@rss)

      author = %{
        name: "mydearxym",
        intro: "this is mydearxym",
        link: "https://coderplaents.com"
      }

      feed =
        feed
        |> Map.merge(%{rss: @rss})
        |> Map.merge(%{author: author})

      {:ok, _rss_record} = CMS.create_blog_rss(feed)

      selected_feed = feed.history_feed |> List.first()
      title = selected_feed |> Map.get(:title)
      link_addr = selected_feed |> Map.get(:link_addr)
      # blog_attrs = mock_attrs(:blog, %{community_id: community.id})
      blog_attrs = %{
        rss: @rss,
        title: title,
        body: mock_rich_text("pleace use content field instead")
      }

      {:ok, blog} = CMS.create_blog(community, blog_attrs, user)
      assert blog.title == title
      assert blog.link_addr == link_addr
      assert blog.blog_author.name == author.name
      assert blog.blog_author.intro == author.intro
      assert blog.blog_author.link == author.link
    end
  end

  describe "fetch rss & curd" do
    @tag :wip2
    test "parse and create basic rss" do
      {:ok, feed} = CMS.blog_rss_info(@rss)
      feed = feed |> Map.merge(%{rss: @rss})

      {:ok, rss_record} = CMS.create_blog_rss(feed)
      assert rss_record.history_feed |> length !== 0

      {:ok, cache} = Cache.get(@cache_pool, @rss)
      assert not is_nil(cache)
    end

    @tag :wip2
    test "create rss with author" do
      {:ok, feed} = CMS.blog_rss_info(@rss)

      author = %{
        name: "mydearxym",
        link: "https://coderplaents.com"
      }

      feed =
        feed
        |> Map.merge(%{rss: @rss})
        |> Map.merge(%{author: author})

      {:ok, rss_record} = CMS.create_blog_rss(feed)
      assert rss_record.author.name == "mydearxym"
    end

    @tag :wip2
    test "update rss with author and exsit feed" do
      {:ok, feed} = CMS.blog_rss_info(@rss)
      {:ok, rss_record} = CMS.create_blog_rss(feed)

      author = %{
        name: "mydearxym",
        link: "https://coderplaents.com"
      }

      attrs = %{rss: rss_record.rss, author: author, history_feed: rss_record.history_feed}
      {:ok, rss_record} = CMS.update_blog_rss(attrs)
      assert rss_record.author.name == "mydearxym"
    end
  end
end
