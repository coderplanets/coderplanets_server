defmodule GroupherServer.Test.Helper.RSSTest do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  alias Helper.{Cache}

  @cache_pool :blog_rss

  describe "get rss" do
    @tag :wip
    test "parse and create basic rss." do
      rss = mock_rss_addr()
      {:ok, feed} = CMS.blog_rss_feed(rss)
      feed = feed |> Map.merge(%{rss: "rss-addr, todo"})

      {:ok, rss_record} = CMS.create_blog_rss(feed)
      assert rss_record.history_feed |> length !== 0

      {:ok, cache} = Cache.get(@cache_pool, rss)
      assert not is_nil(cache)
    end

    @tag :wip
    test "create rss with author" do
      {:ok, feed} = CMS.blog_rss_feed(mock_rss_addr())

      author = %{
        name: "mydearxym",
        link: "https://coderplaents.com"
      }

      feed =
        feed
        |> Map.merge(%{rss: "rss-addr, todo"})
        |> Map.merge(%{author: author})

      {:ok, rss_record} = CMS.create_blog_rss(feed)
      assert rss_record.author.name == "mydearxym"
    end
  end
end
