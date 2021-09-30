defmodule GroupherServer.Test.Query.CMS.BlogRSS do
  use GroupherServer.TestTools

  @rss mock_rss_addr()

  setup do
    guest_conn = simu_conn(:guest)
    user_conn = simu_conn(:user)

    {:ok, ~m(user_conn guest_conn)a}
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
  #
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
