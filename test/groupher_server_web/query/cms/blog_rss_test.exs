defmodule GroupherServer.Test.Query.CMS.BlogRSS do
  use GroupherServer.TestTools

  alias GroupherServer.CMS
  @rss mock_rss_addr()

  setup do
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn)a}
  end

  @query """
  mutation($rss: String!, $name: String, $link: String, $intro: String, $github: String, $twitter: String) {
    updateRssAuthor(rss: $rss, name: $name, link: $link, intro: $intro, github: $github, twitter: $twitter) {
      author {
        name
        intro
        github
        twitter
      }
    }
  }
  """
  test "update rss author info", ~m(user_conn)a do
    {:ok, feed} = CMS.blog_rss_info(@rss)
    feed = feed |> Map.merge(%{rss: @rss})
    {:ok, _rss_record} = CMS.create_blog_rss(feed)

    variables = %{
      rss: @rss,
      name: "mydearxym",
      twitter: "https://twitter.com/xxx",
      github: "https://github.com/xxx"
    }

    results = user_conn |> mutation_result(@query, variables, "updateRssAuthor")

    author = results["author"]
    assert author["name"] == "mydearxym"
    assert author["twitter"] == "https://twitter.com/xxx"
    assert author["github"] == "https://github.com/xxx"
  end

  @query """
  query($rss: String!) {
    blogRssInfo(rss: $rss) {
      title
      subtitle
      link
      updated
      author {
        name
        intro
        github
        twitter
      }
      historyFeed {
        title
        digest
        linkAddr
        content
        published
        updated
      }
    }
  }
  """
  test "basic graphql query blog rss info", ~m(user_conn)a do
    variables = %{rss: @rss}
    results = user_conn |> query_result(@query, variables, "blogRssInfo")

    assert not is_nil(results["title"])
  end

  test "invalid rss will get error", ~m(user_conn)a do
    variables = %{rss: "invalid rss address"}
    # results = user_conn |> query_result(@query, variables, "blogRssInfo")
    assert user_conn |> query_get_error?(@query, variables, ecode(:invalid_blog_rss))
    # IO.inspect(results, label: "iiii")
  end
end
